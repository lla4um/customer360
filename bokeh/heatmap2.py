import pandas as pd

from bokeh.io import output_file, show
from bokeh.models import BasicTicker, ColorBar, LinearColorMapper, ColumnDataSource, PrintfTickFormatter
from bokeh.plotting import figure
from bokeh.transform import transform
from sklearn.datasets import make_classification
from random import *

def create_heatmap(df):

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

    X, Y = make_classification(n_samples=100, n_classes=4, n_features=12, n_redundant=0, n_informative=12, scale=1000, n_clusters_per_class=1)
    df3 = pd.DataFrame(X)
    # ensure all values are positive (this is needed for our customer 360 use-case)
    df3 = df3.abs()

    # rename X columns
    df3 = rename_columns(df3)
    # and add the Y
    df3['y'] = Y
    print("vvvvvvvvvvvvvvvvvvvvv")
    print(df3)
    # split df into cluster groups
    grouped = df3.groupby(['y'], sort=True)
    # compute sums for every column in every group
    sums = grouped.sum()
    #persona=list(sums.index) * len(sums.columns)
    persona=['0','1','2','3']
    score = [0] * len(products)
    for x in range(len(score)):
        score2 = [0]*len(persona)
        for y in range(len(score2)):
            score2[y] = randint(1, 100)
        score[x] = score2
    print(score)

    df1 = pd.DataFrame(
        score,
        columns=persona,
        index=products)
    df1.index.name = 'Products'
    df1.columns.name = 'Personas'

    df2 = pd.DataFrame(
        [[10, 0, 4, 1], [1, 10, 6, 1], [1, 1, 9, 7], [5, 2, 9, 3], [4, 4, 4, 4], [1, 1, 2, 6], [1, 10, 9, 7], [1,3, 2, 7], [1, 6, 8, 7]],
        columns=['A', 'B', 'C', 'D'],
        index=['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'])
    df2.index.name = 'Treatment'
    df2.columns.name = 'Prediction'

    # Prepare data.frame in the right format
    df1 = df1.stack().rename("score").reset_index()
    df2 = df2.stack().rename("value").reset_index()


    # You can use your own palette here
    colors = ["#75968f", "#a5bab7", "#c9d9d3", "#e2e2e2", "#dfccce", "#ddb7b1", "#cc7878", "#933b41", "#550b1d"]

    # Had a specific mapper to map color with value
    mapper1 = LinearColorMapper(
        palette=colors, low=df1.score.min(), high=df1.score.max())
    mapper = LinearColorMapper(
        palette=colors, low=df2.value.min(), high=df2.value.max())
    # Define a figure
    p1 = figure(
        plot_width=900,
        plot_height=400,
        title="Customer Profiles",
        x_range=list(df1.Products.drop_duplicates()),
        y_range=list(df1.Personas.drop_duplicates()),
        toolbar_location=None,
        tools="",
        x_axis_location="above")

    p = figure(
        plot_width=800,
        plot_height=300,
        title="My plot",
        x_range=list(df2.Treatment.drop_duplicates()),
        y_range=list(df2.Prediction.drop_duplicates()),
        toolbar_location=None,
        tools="",
        x_axis_location="above")
    # Create rectangle for heatmap
    p1.rect(
        x="Products",
        y="Personas",
        width=1,
        height=1,
        source=ColumnDataSource(df1),
        line_color=None,
        fill_color=transform('score', mapper1))

    p.rect(
        x="Treatment",
        y="Prediction",
        width=1,
        height=1,
        source=ColumnDataSource(df2),
        line_color=None,
        fill_color=transform('value', mapper))

    # Add legend
    color_bar = ColorBar(
        color_mapper=mapper,
        location=(0, 0),
        ticker=BasicTicker(desired_num_ticks=len(colors)))

    p1.add_layout(color_bar, 'right')
    p.add_layout(color_bar, 'right')

    return p1
