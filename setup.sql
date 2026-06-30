-- ════════════════════════════════════════════════════════════════
--  DA Internship LMS — Supabase Database Setup (Updated)
--  Copy this entire file and paste into:
--  Supabase Dashboard → SQL Editor → New Query → Run
-- ════════════════════════════════════════════════════════════════

-- ── 1. PROFILES (extends Supabase auth.users) ──────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email       TEXT,
  full_name   TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'intern' CHECK (role IN ('admin','intern')),
  batch       TEXT DEFAULT 'Batch 2026',
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. TEST WINDOWS (admin opens/closes each week's test) ───────
CREATE TABLE IF NOT EXISTS public.test_windows (
  week_number INT PRIMARY KEY CHECK (week_number BETWEEN 1 AND 16),
  is_open     BOOLEAN DEFAULT false,
  phase_name  TEXT,
  test_title  TEXT,
  max_score   INT DEFAULT 25,
  duration_min INT DEFAULT 30,
  opened_at   TIMESTAMPTZ,
  closed_at   TIMESTAMPTZ
);

-- ── 3. TEST RESULTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.test_results (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  intern_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  week_number  INT NOT NULL,
  score        INT NOT NULL,
  max_score    INT NOT NULL,
  percentage   NUMERIC(5,2) GENERATED ALWAYS AS (ROUND((score::NUMERIC / max_score) * 100, 2)) STORED,
  answers      JSONB DEFAULT '{}',
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(intern_id, week_number)
);

-- ── 4. QUESTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.questions (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  week_number   INT NOT NULL,
  question_text TEXT NOT NULL,
  option_a      TEXT NOT NULL,
  option_b      TEXT NOT NULL,
  option_c      TEXT NOT NULL,
  option_d      TEXT NOT NULL,
  correct       CHAR(1) NOT NULL CHECK (correct IN ('A','B','C','D')),
  marks         INT DEFAULT 2,
  sort_order    INT DEFAULT 0,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY & RECURSION BYPASS FUNCTION
-- ════════════════════════════════════════════════════════════════
ALTER TABLE public.profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions    ENABLE ROW LEVEL SECURITY;

-- Create helper function to check admin role without causing RLS recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Profiles Policies
CREATE POLICY "Users can read own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admin reads all profiles"   ON public.profiles FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin manages all profiles" ON public.profiles FOR ALL    USING (public.is_admin());
CREATE POLICY "Users insert own profile"   ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Test Windows Policies
CREATE POLICY "Everyone reads test windows" ON public.test_windows FOR SELECT USING (true);
CREATE POLICY "Admin manages test windows"  ON public.test_windows FOR ALL    USING (public.is_admin());

-- Test Results Policies
CREATE POLICY "Interns read own results"  ON public.test_results FOR SELECT USING (intern_id = auth.uid());
CREATE POLICY "Interns submit results"    ON public.test_results FOR INSERT WITH CHECK (intern_id = auth.uid());
CREATE POLICY "Admin reads all results"   ON public.test_results FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin manages results"     ON public.test_results FOR ALL    USING (public.is_admin());

-- Questions Policies
CREATE POLICY "Everyone reads questions"  ON public.questions FOR SELECT USING (true);
CREATE POLICY "Admin manages questions"   ON public.questions FOR ALL    USING (public.is_admin());

-- ════════════════════════════════════════════════════════════════
--  AUTO-CREATE PROFILE AFTER SIGNUP (trigger)
-- ════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, batch)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Unknown'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'intern'),
    COALESCE(NEW.raw_user_meta_data->>'batch', 'Batch 2026')
  )
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, full_name = EXCLUDED.full_name, batch = EXCLUDED.batch;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ════════════════════════════════════════════════════════════════
--  SEED: TEST WINDOWS (all 16 weeks, all closed by default)
-- ════════════════════════════════════════════════════════════════
INSERT INTO public.test_windows (week_number, phase_name, test_title, max_score, duration_min) VALUES
(1,  'Phase 1','What is Data Analytics?',25,30),
(2,  'Phase 1','Data Lifecycle & KPIs',25,30),
(3,  'Phase 2','Finance & Business Fundamentals',30,35),
(4,  'Phase 2','Marketing, Operations & HR',30,35),
(5,  'Phase 3','Descriptive Statistics',35,40),
(6,  'Phase 3','Probability, Hypothesis & Data Quality',35,40),
(7,  'Phase 4','Excel Formulas & Functions',30,35),
(8,  'Phase 4','Power Query & Data Cleaning',30,35),
(9,  'Phase 5','SQL Basics',35,40),
(10, 'Phase 5','Advanced SQL',35,40),
(11, 'Phase 6','Python Basics & Pandas',35,40),
(12, 'Phase 6','EDA with Python',35,40),
(13, 'Phase 7','Data Visualization & Power BI',30,35),
(14, 'Phase 7','Storytelling & Dashboard Design',30,35),
(15, 'Phase 8','Capstone Progress Check',30,30),
(16, 'Phase 8','Final Capstone Presentation',100,60)
ON CONFLICT DO NOTHING;

-- ════════════════════════════════════════════════════════════════
--  SEED: MCQ QUESTIONS  (5 per week for weeks 1-14)
-- ════════════════════════════════════════════════════════════════

-- ── WEEK 1 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(1,'Which type of analytics answers "What happened?"','Predictive','Descriptive','Prescriptive','Diagnostic','B',2,1),
(1,'A hospital predicts patient readmissions within 30 days. This is:','Descriptive','Diagnostic','Predictive','Prescriptive','C',2,2),
(1,'A navigation app recommending the fastest route in real-time is:','Descriptive','Diagnostic','Predictive','Prescriptive','D',2,3),
(1,'Customer satisfaction scored 1–5 stars is which data type?','Nominal','Ratio','Ordinal','Interval','C',2,4),
(1,'"Number of sales calls made this week" is a:','Lagging indicator','Leading indicator','Financial KPI','Vanity metric','B',2,5);

-- ── WEEK 2 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(2,'Which step removes duplicates and fixes formatting?','Collection','Cleaning','Analysis','Visualization','B',2,1),
(2,'A KPI differs from a metric because it:','Is always financial','Is only for executives','Is tied to a strategic goal','Must be automated','C',2,2),
(2,'Which is NOT a property of a SMART KPI?','Specific','Measurable','Time-bound','Vague and open to interpretation','D',2,3),
(2,'Revenue earned last quarter is a:','Leading indicator','Lagging indicator','Predictive metric','Real-time KPI','B',2,4),
(2,'Analysts spend most of their time on which phase?','Visualization','Collecting and cleaning data','Modeling','Reporting','B',2,5);

-- ── WEEK 3 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(3,'Revenue – COGS = ?','Net Profit','EBITDA','Gross Profit','Operating Income','C',2,1),
(3,'Marketing spend PKR 600K, 300 new customers. CAC = ?','PKR 1,000','PKR 1,500','PKR 2,000','PKR 3,000','C',2,2),
(3,'A healthy LTV:CAC ratio target is:','1:1','2:1','3:1 or higher','Always 10:1','C',2,3),
(3,'Fixed costs are:','Based on production volume','Constant regardless of output','Only marketing costs','One-time expenses','B',2,4),
(3,'Revenue PKR 8M, Net Profit PKR 1.6M. Net Profit Margin = ?','10%','15%','20%','25%','C',2,5);

-- ── WEEK 4 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(4,'A customer making a purchase is at which funnel stage?','Awareness','Consideration','Conversion','Retention','C',2,1),
(4,'CTR = 1000 clicks from 50,000 impressions. Result = ?','1%','2%','5%','50%','B',2,2),
(4,'Ad spend PKR 300K, Revenue PKR 1.5M. ROAS = ?','3x','5x','2x','0.2x','B',2,3),
(4,'500 employees, 60 leave during the year. Turnover rate approx = ?','8%','10%','12%','20%','C',2,4),
(4,'The Lean 7 Wastes acronym is:','DEFECTS','REDUCE','TIMWOOD','IMPROVE','C',2,5);

-- ── WEEK 5 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(5,'Mean = 120K, Median = 60K. This distribution is:','Symmetric','Left-skewed','Right-skewed','Normal','C',2,1),
(5,'In a normal distribution ~95% of data falls within:','1 SD','2 SD','3 SD','0.5 SD','B',2,2),
(5,'Which measure is most resistant to outliers?','Mean','Variance','Median','Range','C',2,3),
(5,'IQR = ?','Mean – Median','Q3 – Q1','Max – Min','Q2 – Q1','B',2,4),
(5,'Outlier rule using IQR: a value is an outlier if it is more than __ × IQR above Q3','1','1.5','2','3','B',2,5);

-- ── WEEK 6 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(6,'p-value = 0.03, α = 0.05. Your decision:','Fail to reject H₀','Reject H₀','Data is inconclusive','Accept H₀ as true','B',2,1),
(6,'Type I Error means:','Failing to reject a false H₀','Rejecting a true H₀','A calculation mistake','Biased sampling','B',2,2),
(6,'Pearson r = –0.85 indicates:','No relationship','Weak positive','Strong negative','Perfect positive','C',2,3),
(6,'"IT" in one table and "I.T." in another violates which data quality dimension?','Accuracy','Completeness','Consistency','Uniqueness','C',2,4),
(6,'Winsorizing an outlier means:','Deleting it','Logging it','Replacing it with the nearest fence value','Doubling it','C',2,5);

-- ── WEEK 7 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(7,'=VLOOKUP(B2,F:H,3,FALSE) returns value from which column?','F','G','H','B','C',2,1),
(7,'INDEX/MATCH is preferred over VLOOKUP because:','Easier to type','Can look LEFT and handles column insertion','VLOOKUP only works with text','Always faster','B',2,2),
(7,'Power Query is best used for:','Creating charts','Automating data cleaning and transformation','Running Python','Building pivot charts','B',2,3),
(7,'=IFERROR(A2/B2, 0) when B2=0 returns:','Error','A2','0','NULL','C',2,4),
(7,'Which feature highlights cells meeting conditions with colors?','Data Validation','Conditional Formatting','PivotChart','Freeze Panes','B',2,5);

-- ── WEEK 8 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(8,'ETL stands for:','Extract, Transfer, Load','Extract, Transform, Load','Evaluate, Test, Launch','Explore, Transform, Locate','B',2,1),
(8,'Salary is missing because high earners refused to report it. This is:','MCAR','MAR','MNAR','Complete data','C',2,2),
(8,'Z-score outlier threshold (common rule): flag values with |Z| greater than:','1','2','3','0.5','C',2,3),
(8,'"Append Queries" in Power Query is equivalent to SQL:','JOIN','UNION','SELECT','WHERE','B',2,4),
(8,'Best imputation for a right-skewed column with missing values:','Mean','Median','Mode','Zero','B',2,5);

-- ── WEEK 9 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(9,'SQL clause to filter rows:','GROUP BY','HAVING','WHERE','ORDER BY','C',2,1),
(9,'INNER JOIN returns:','All rows from both tables','All rows from left','Only matching rows from both','All rows from right','C',2,2),
(9,'HAVING clause filters:','Rows before grouping','Groups after aggregation','NULL values','Columns by name','B',2,3),
(9,'Sort results from highest to lowest salary:','ORDER BY Salary ASC','ORDER BY Salary DESC','SORT BY Salary HIGH','GROUP BY Salary DESC','B',2,4),
(9,'PRIMARY KEY:','Most important column','Uniquely identifies each row','Links to another table','Always first column','B',2,5);

-- ── WEEK 10 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(10,'CTEs are defined using which keyword?','DEFINE','TEMP','WITH','AS','C',2,1),
(10,'Difference between RANK() and DENSE_RANK():','They are identical','RANK() skips numbers after ties; DENSE_RANK() does not','DENSE_RANK() skips; RANK() does not','RANK() only works with ORDER BY','B',2,2),
(10,'LAG(Salary, 1) returns:','Next row salary','Previous row salary','Average salary','Salary two rows ahead','B',2,3),
(10,'PARTITION BY in a window function:','Splits into multiple queries','Groups data without collapsing rows','Filters rows before window function','Same as GROUP BY','B',2,4),
(10,'NTILE(4) divides rows into:','4 equal groups','4 rows per group','Groups of 4 rows','Top 4 rows only','A',2,5);

-- ── WEEK 11 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(11,'df.shape returns:','Column names','(rows, columns) tuple','Data types','First 5 rows','B',2,1),
(11,'df.describe() provides:','Column names and types','Summary statistics for numeric columns','First 10 rows','Missing value counts','B',2,2),
(11,'Filter rows where Salary > 50000:','df.filter("Salary > 50000")','df[df["Salary"] > 50000]','df.where(Salary > 50000)','df.select(Salary > 50000)','B',2,3),
(11,'Merge df1 and df2 on "ID":','df1.append(df2, on="ID")','pd.merge(df1, df2, on="ID")','df1.join(df2, key="ID")','pd.concat([df1,df2], on="ID")','B',2,4),
(11,'df.fillna(0) does what?','Removes NaN rows','Replaces all NaN with 0','Fills only numeric NaN','Counts NaN values','B',2,5);

-- ── WEEK 12 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(12,'First step in the EDA workflow is:','Build charts','Run hypothesis tests','Understand shape: rows, columns, types','Clean all data','C',2,1),
(12,'Univariate analysis examines:','Relationships between two variables','One variable at a time','Multiple variables together','Only categorical columns','B',2,2),
(12,'A correlation heatmap shows:','Distribution of one variable','Pairwise correlations between all numeric variables','Time trends','Category comparisons','B',2,3),
(12,'Seaborn function for box plots:','sns.hist()','sns.scatter()','sns.boxplot()','sns.bar()','C',2,4),
(12,'Z-score outlier detection flags values with |Z| greater than:','1','2','3','0.5','C',2,5);

-- ── WEEK 13 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(13,'Best chart for trends over time:','Bar Chart','Pie Chart','Histogram','Line Chart','D',2,1),
(13,'Best chart for distribution of a numeric variable:','Line Chart','Pie Chart','Histogram','Bar Chart','C',2,2),
(13,'In Power BI, DAX stands for:','Data Aggregation eXpression','Data Analysis Expressions','Dynamic Analytics eXecution','Dashboard Axis eXtension','B',2,3),
(13,'A Slicer in Power BI is used to:','Delete data','Filter visuals interactively','Create calculated columns','Import data','B',2,4),
(13,'Pie chart should NOT be used when:','2 categories','3 categories','4 categories','More than 6 categories','D',2,5);

-- ── WEEK 14 ──────────────────────────────────────────────────────
INSERT INTO public.questions (week_number,question_text,option_a,option_b,option_c,option_d,correct,marks,sort_order) VALUES
(14,'The SCQA storytelling framework stands for:','Story, Chart, Question, Answer','Situation, Complication, Question, Answer','Summary, Context, Query, Action','Structure, Claim, Question, Argument','B',2,1),
(14,'Data-ink ratio principle (Edward Tufte) means:','Use as many colors as possible','Maximize decorative elements','Maximize ink used to show actual data','Always use 3D charts','C',2,2),
(14,'Color universally indicating negative/declining values:','Blue','Orange','Red','Purple','C',2,3),
(14,'The 5-second rule in data visualization means:','Charts load in 5 seconds','A good chart is understood in 5 seconds','Refresh every 5 seconds','5 colors max per chart','B',2,4),
(14,'Presenting to a non-technical audience, you should:','Lead with methodology','Use statistical jargon','Lead with the insight and business impact','Show all 20 charts','C',2,5);
