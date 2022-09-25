##########################
# Create heatmap
##########################

import pandas as pd
from math import pi
from bokeh.models import BasicTicker, ColorBar, LinearColorMapper, PrintfTickFormatter
from bokeh.plotting import figure, show
from sklearn.datasets import make_classification
from bokeh.models import ColumnDataSource, FixedTicker
#from bkcharts.charts import HeatMap
from bokeh.models.widgets import  DataTable, TableColumn
from bokeh.models import HoverTool



def create_heatmap(df):

    # test to redo heatmap
    ###################################


    # reshape to 1D array or rates with a month and year for each row.
    TOOLS = "hover,save,pan,box_zoom,reset,wheel_zoom"

    ########################################
    # end test


    products=['Debit Card',
              'Personal Credit Card',
              'Business Credit Card',
              'Home Mortgage Loan',
              'Auto Loan',
              'Brokerage Account',
              'Roth IRA',
              '401k',
              'Home Insurance',
              'Automobile Insurance',
              'Medical Insurance',
              'Life Insurance',
              'Cell Phone',
              'Landline'
              ]

    def rename_columns(df):
        df = df.copy()
        df.columns = [products[i] for i in df.columns]
        return df

    # create an artificial dataset with 3 clusters
    X, Y = make_classification(n_samples=100, n_classes=4, n_features=12, n_redundant=0, n_informative=12,
                               scale=1000, n_clusters_per_class=1)
    df2 = pd.DataFrame(X)
    # ensure all values are positive (this is needed for our customer 360 use-case)
    df2 = df2.abs()

    # rename X columns
    df2 = rename_columns(df2)
    # and add the Y
    df2['y'] = Y
    print(df2)
    # split df into cluster groups
    grouped = df2.groupby(['y'], sort=True)
    # compute sums for every column in every group

    sums = grouped.sum()

    persona=list(sums.index) * len(sums.columns)
    persona2=['0','1','2','3']
    score = [0] * len(persona)
    product=[item for item in list(sums.columns) for i in range(len(sums.index))]
    p = figure(title="Customer Profiles",
           x_range=persona2, y_range=products,
           x_axis_location="above", width=900, height=400,
           tools=TOOLS, toolbar_location='below')
    import string
    import random
    for x in range(len(score)):
        score[x] = ord(random.choice(string.ascii_letters))
    data2=dict(
        persona=list(sums.index) * len(sums.columns),
        product=[item for item in list(sums.columns) for i in range(len(sums.index))],
        score=score
    )

    p.grid.grid_line_color = None
    p.axis.axis_line_color = None
    p.axis.major_tick_line_color = None
    p.axis.major_label_text_font_size = "10px"
    p.axis.major_label_standoff = 0
    p.xaxis.major_label_orientation = pi / 3
    df4 = pd.DataFrame(data2)

    colors = ["#75968f", "#a5bab7", "#c9d9d3", "#e2e2e2", "#dfccce", "#ddb7b1", "#cc7878", "#933b41", "#550b1d"]
    mapper = LinearColorMapper(palette=colors, low=df4.score.min(), high=df4.score.max())

    hm = p.rect(x="product", y="persona", width=10, height=10,
       source=data2,
       fill_color={'field': 'score', 'transform': mapper},
       line_color=None)

    #color_bar = ColorBar(color_mapper=mapper, major_label_text_font_size="16px",
    #                 ticker=BasicTicker(desired_num_ticks=len(colors)),
    #                 formatter=PrintfTickFormatter(format="%d%%"),
    #                 label_standoff=6, border_line_color=None)
    #p.add_layout(color_bar, 'right')

    return p
