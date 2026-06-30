import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        if self._pageNumber == 1:
            return # Skip title page number
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#64748b"))
        
        # Header
        self.drawString(inch, 10.5 * inch, "KPITB Data Analytics Internship Roadmap")
        self.setStrokeColor(colors.HexColor("#e2e8f0"))
        self.setLineWidth(0.5)
        self.line(inch, 10.4 * inch, 7.5 * inch, 10.4 * inch)
        
        # Footer
        self.line(inch, 0.75 * inch, 7.5 * inch, 0.75 * inch)
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(7.5 * inch, 0.55 * inch, page_text)
        self.drawString(inch, 0.55 * inch, "Confidential - KPITB Capacity Building Program 2026")
        self.restoreState()

def build_pdf(filename="kpitb_da_roadmap.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        rightMargin=inch * 0.75,
        leftMargin=inch * 0.75,
        topMargin=inch * 0.85,
        bottomMargin=inch * 0.85
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#0f1729"),
        spaceAfter=8
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#475569"),
        spaceAfter=20
    )
    
    section_heading = ParagraphStyle(
        'SectionHeading',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=16,
        leading=20,
        textColor=colors.HexColor("#0f1729"),
        spaceBefore=14,
        spaceAfter=10,
        keepWithNext=True
    )

    phase_title_style = ParagraphStyle(
        'PhaseTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=colors.HexColor("#1e3a8a"),
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'DocBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor("#334155"),
        spaceAfter=6
    )

    body_bold = ParagraphStyle(
        'DocBodyBold',
        parent=body_style,
        fontName='Helvetica-Bold'
    )
    
    bullet_style = ParagraphStyle(
        'DocBullet',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    story = []

    # ── TITLE PAGE ──
    story.append(Spacer(1, 0.5 * inch))
    story.append(Paragraph("KPITB Data Analytics Internship Program", title_style))
    story.append(Paragraph("A Comprehensive 16-Week Training & Capacity Building Roadmap (2026)", subtitle_style))
    
    # Overview Panel
    overview_data = [
        [Paragraph("<b>Duration:</b>", body_style), Paragraph("16 Weeks (4 Months)", body_style)],
        [Paragraph("<b>Target Audience:</b>", body_style), Paragraph("Beginner to Intermediate Interns", body_style)],
        [Paragraph("<b>Training Mode:</b>", body_style), Paragraph("Blended (Instructor-led lectures + Guided Labs & Projects)", body_style)],
        [Paragraph("<b>Core Goal:</b>", body_style), Paragraph("To produce job-ready Data Analysts equipped with industry-relevant skills in Excel, SQL, Python, and Power BI.", body_style)],
    ]
    t_overview = Table(overview_data, colWidths=[1.5*inch, 5.5*inch])
    t_overview.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('LINEBELOW', (0,0), (-1,-1), 0.5, colors.HexColor("#e2e8f0")),
    ]))
    story.append(t_overview)
    story.append(Spacer(1, 0.4 * inch))

    # Executive Summary
    story.append(Paragraph("Executive Summary", section_heading))
    story.append(Paragraph(
        "This curriculum is designed to systematically transform interns with zero background into data professional capable of extracting insights, wrangling databases, and building robust BI reports. It balances foundational knowledge (mindset, financial context, stats) with hard technical execution (Excel, SQL databases, Python script analysis, Power BI storytelling) and terminates in a cumulative Capstone presentation reviewed by senior management.",
        body_style
    ))
    story.append(Spacer(1, 0.3 * inch))

    # Phase Grid Summary
    story.append(Paragraph("Roadmap Phases at a Glance", section_heading))
    
    grid_data = [
        ["Phase", "Focus Area", "Weeks", "Core Tools"],
        ["Phase 1", "Foundations & Analytical Mindset", "Weeks 1-2", "Excel, Business Mindset"],
        ["Phase 2", "Business Domain & Economics", "Weeks 3-4", "Finance Metrics, Marketing Funnels"],
        ["Phase 3", "Statistics Theory & Probability", "Weeks 5-6", "Descriptive Stats, Hypothesis Testing"],
        ["Phase 4", "Excel & Data Wrangling", "Weeks 7-8", "XLOOKUP, Power Query, ETL"],
        ["Phase 5", "SQL Database Querying", "Weeks 9-10", "Relational Database, Joins, Group By"],
        ["Phase 6", "Python & Pandas Scripting", "Weeks 11-12", "Jupyter, DataFrames, Data Cleaning"],
        ["Phase 7", "Visualization & Power BI", "Weeks 13-14", "Star Schema, DAX, Interactive Reports"],
        ["Phase 8", "Capstone Portfolio Project", "Weeks 15-16", "End-to-End Analysis & Presentation"],
    ]
    t_grid = Table(grid_data, colWidths=[0.8*inch, 2.8*inch, 1.0*inch, 2.4*inch])
    t_grid.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0f1729")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 9.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#cbd5e1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#f8fafc")]),
    ]))
    story.append(t_grid)
    
    story.append(PageBreak())

    # ── PHASE-BY-PHASE DETAILED SYLLABUS ──
    story.append(Paragraph("Detailed Syllabus Breakdown", section_heading))
    
    # Phase 1
    p1 = []
    p1.append(Paragraph("Phase 1: Foundations & Analytical Mindset (Weeks 1-2)", phase_title_style))
    p1.append(Paragraph("<b>Objective:</b> Establish the terminology, analytics categories, data scales, and ethical structures essential to a data analyst.", body_style))
    p1.append(Paragraph("• <b>Week 1 Topics:</b> descriptive vs. diagnostic vs. predictive vs. prescriptive analytics; structure of quantitative vs. qualitative data scales (Nominal, Ordinal, Interval, Ratio - NOIR); role boundaries of Data Analyst vs. Data Engineer vs. Data Scientist.", bullet_style))
    p1.append(Paragraph("• <b>Week 2 Topics:</b> 6-stage Data Lifecycle (Collection, Cleaning, Exploration, Analysis, Visualization, Decision); KPI design utilizing the SMART framework; understanding leading vs. lagging indicators in business contexts; data ethics, governance, PII, and bias.", bullet_style))
    p1.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p1))

    # Phase 2
    p2 = []
    p2.append(Paragraph("Phase 2: Business & Finance Domain Knowledge (Weeks 3-4)", phase_title_style))
    p2.append(Paragraph("<b>Objective:</b> Equip analysts to understand department terminology so their dashboard solutions fit commercial realities.", body_style))
    p2.append(Paragraph("• <b>Week 3 Topics:</b> Basic accounting (Revenue, COGS, Gross Profit, Net Income, EBITDA); customer valuation economics (CAC, LTV, Churn, Payback Period); Fixed vs. Variable costs, margins, and operational break-even points.", bullet_style))
    p2.append(Paragraph("• <b>Week 4 Topics:</b> Marketing analytics metrics (Click-Through Rate, Impressions, CPA, ROAS) and customer conversion funnels; Operations metrics (Cycle Time, Lead Time, and Throughput) and the TIMWOOD Lean waste system; HR metrics (turnover, recruitment funnel, training ROI).", bullet_style))
    p2.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p2))

    # Phase 3
    p3 = []
    p3.append(Paragraph("Phase 3: Statistics Theory & Probability (Weeks 5-6)", phase_title_style))
    p3.append(Paragraph("<b>Objective:</b> Teach interns to differentiate between random noise and real, statistically significant trends.", body_style))
    p3.append(Paragraph("• <b>Week 5 Topics:</b> Measures of center (Mean, Median, Mode) and spread (SD, Variance, Range); identifying outliers using the IQR rule (1.5xIQR fences); skewness, kurtosis, and box plot visual indicators.", bullet_style))
    p3.append(Paragraph("• <b>Week 6 Topics:</b> Probability theory and distributions (Normal, Binomial, Poisson); Hypothesis Testing protocol (Null vs. Alternative hypotheses, Alpha thresholds, p-values); Type I vs. Type II errors; Z-tests, independent samples t-tests, and ANOVA.", bullet_style))
    p3.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p3))

    # Phase 4
    p4 = []
    p4.append(Paragraph("Phase 4: Excel & Data Wrangling (Weeks 7-8)", phase_title_style))
    p4.append(Paragraph("<b>Objective:</b> Master professional advanced spreadsheet operations and Power Query ETL mechanisms.", body_style))
    p4.append(Paragraph("• <b>Week 7 Topics:</b> Advanced lookup mechanics (VLOOKUP, INDEX/MATCH, XLOOKUP); conditional aggregations (SUMIFS, COUNTIFS, AVERAGEIFS); logical nesting; text and date manipulation functions.", bullet_style))
    p4.append(Paragraph("• <b>Week 8 Topics:</b> Extract, Transform, Load (ETL) pipelines using Power Query; data cleaning, column splitting, unpivoting, merging, and appending tables; introduction to M language and query folding.", bullet_style))
    p4.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p4))

    story.append(PageBreak())

    # Phase 5
    p5 = []
    p5.append(Paragraph("Phase 5: SQL Database Querying (Weeks 9-10)", phase_title_style))
    p5.append(Paragraph("<b>Objective:</b> Gain fluent access to relational databases, write aggregate queries, and design analytical partitions.", body_style))
    p5.append(Paragraph("• <b>Week 9 Topics:</b> SELECT syntax, WHERE conditions, ORDER BY sorting; INNER, LEFT, RIGHT, and FULL joins; aggregate functions (COUNT, SUM, AVG, MIN, MAX) combined with GROUP BY and HAVING clauses.", bullet_style))
    p5.append(Paragraph("• <b>Week 10 Topics:</b> Common Table Expressions (CTEs) utilizing WITH; Analytical Window Functions (OVER, PARTITION BY, ROW_NUMBER, RANK, DENSE_RANK); positional windowing (LAG, LEAD); database indexing concepts (clustered vs. non-clustered) and query optimization.", bullet_style))
    p5.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p5))

    # Phase 6
    p6 = []
    p6.append(Paragraph("Phase 6: Python & Pandas Scripting (Weeks 11-12)", phase_title_style))
    p6.append(Paragraph("<b>Objective:</b> Transition from Excel to automated code-based data wrangling and manipulation using Jupyter.", body_style))
    p6.append(Paragraph("• <b>Week 11 Topics:</b> Python core variables, lists, dicts, logic flow, and custom functions; Pandas structures (Series vs. DataFrames); loading CSV/Excel sources; indexing and selecting rows using loc/iloc; handling missing data (fillna, dropna).", bullet_style))
    p6.append(Paragraph("• <b>Week 12 Topics:</b> Aggregating DataFrames using groupby and pivot tables; merging and joining tables; data visualization libraries (Matplotlib, Seaborn heatmaps/scatterplots); Z-score outlier detection in Python.", bullet_style))
    p6.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p6))

    # Phase 7
    p7 = []
    p7.append(Paragraph("Phase 7: Visualization & Power BI Dashboarding (Weeks 13-14)", phase_title_style))
    p7.append(Paragraph("<b>Objective:</b> Deploy interactive dashboards utilizing Star Schema modeling, measures, and visual hierarchy.", body_style))
    p7.append(Paragraph("• <b>Week 13 Topics:</b> Star Schema layout (Fact tables, Dimension tables, active/inactive relationships); DAX calculations (Calculated columns vs. Measures, CALCULATE function, DIVIDE); visual guidelines (Data-ink ratio, 5-second rule).", bullet_style))
    p7.append(Paragraph("• <b>Week 14 Topics:</b> Storytelling frameworks (SCQA); reducing dashboard visual clutter (using Gestalt proximity/similarity principles); color psychology (accent vs. neutral grey signaling); audience-tailored presentations (C-Suite vs. Tech).", bullet_style))
    p7.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p7))

    # Phase 8
    p8 = []
    p8.append(Paragraph("Phase 8: Capstone Portfolio Project & Graduation (Weeks 15-16)", phase_title_style))
    p8.append(Paragraph("<b>Objective:</b> Apply the entire end-to-end curriculum to a real-world business dataset, culminating in a structured executive deck.", body_style))
    p8.append(Paragraph("• <b>Deliverables:</b> Interns work on custom datasets to: (1) Define 5 core analytical business questions; (2) Design a SQL database structure; (3) Clean and explore the data in Python; (4) Build an interactive Power BI dashboard; (5) Present a 15-slide deck outlining actionable recommendations.", bullet_style))
    p8.append(Spacer(1, 0.1 * inch))
    story.append(KeepTogether(p8))

    doc.build(story, canvasmaker=NumberedCanvas)

if __name__ == "__main__":
    build_pdf()
