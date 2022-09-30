from fastapi import FastAPI
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import defaultdict

import surprise

from surprise.reader import Reader
from surprise import Dataset
from surprise.model_selection import GridSearchCV

from surprise.model_selection import cross_validate

from surprise import SVD
from surprise import NMF

np.random.seed(42)

from io import BytesIO
from zipfile import ZipFile
from urllib.request import urlopen

from pydantic import BaseModel

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Item(BaseModel):
    ratings: list[dict] = []

def get_top_n(predictions, userId, movies_df, ratings_df, n = 10):
    top_n = defaultdict(list)
    for uid, iid, true_r, est, _ in predictions:
        top_n[uid].append((iid, est))

    for uid, user_ratings in top_n.items():
        user_ratings.sort(key = lambda x: x[1], reverse = True)
        top_n[uid] = user_ratings[: n ]
 
    user_data = ratings_df[ratings_df.userId == (userId)]
    print('User {0} has already rated {1} movies.'.format(userId, user_data.shape[0]))

    preds_df = pd.DataFrame([(id, pair[0],pair[1]) for id, row in top_n.items() for pair in row],
                        columns=["userId" ,"movieId","rat_pred"])
   
    pred_usr = preds_df[preds_df["userId"] == (userId)].merge(movies_df, how = 'left', left_on = 'movieId', right_on = 'movieId')
            
    hist_usr = ratings_df[ratings_df.userId == (userId) ].sort_values("rating", ascending = False).merge\
    (movies_df, how = 'left', left_on = 'movieId', right_on = 'movieId')
    
    
    return hist_usr, pred_usr

r = urlopen("http://files.grouplens.org/datasets/movielens/ml-latest-small.zip")
zipfile = ZipFile(BytesIO(r.read()))

ratings_df = pd.read_csv(zipfile.open('ml-latest-small/ratings.csv'))
movies_df = pd.read_csv(zipfile.open('ml-latest-small/movies.csv'))


min_movie_ratings = 2 
min_user_ratings =  5 


ratings_flrd_df = ratings_df.groupby("movieId").filter(lambda x: x['movieId'].count() >= min_movie_ratings)
ratings_flrd_df = ratings_flrd_df.groupby("userId").filter(lambda x: x['userId'].count() >= min_user_ratings)



"{0} movies deleted; all movies are now rated at least: {1} times. Old dimensions: {2}; New dimensions: {3}"\
.format(len(ratings_df.movieId.value_counts()) - len(ratings_flrd_df.movieId.value_counts())\
        ,min_movie_ratings,ratings_df.shape, ratings_flrd_df.shape )

reader = Reader(rating_scale=(0.5, 5)) 
data = Dataset.load_from_df(ratings_flrd_df[["userId",	"movieId",	"rating"]], reader=reader)

trainset = data.build_full_trainset()

testset = trainset.build_anti_testset()

algo_SVD = SVD(n_factors = 11)
algo_SVD.fit(trainset)
predictions = algo_SVD.test(testset)


df_input = ratings_flrd_df[["userId",	"movieId",	"rating"]]

movie_data = movies_df.to_dict(orient='records')
movies_df_length= len(movies_df)

@app.get("/moviedata")
def read_movie_data(pagenum: int = 1, pagesize:int = 20):
    start = (pagenum-1) * pagesize
    end = start + pagesize

    response = {
        "movie_data": movie_data[start:end],
        "total": movies_df_length,
        "count": pagesize,
        "page": pagenum,
        "pagination": {}
    }

    if end >= movies_df_length:
        response["pagination"]["next"] = None
        
        if pagenum > 1:
            response["pagination"]["previous"] = f"/moviedata?pagenum={pagenum-1}&pagesize={pagesize}"
        else:
            response["pagination"]["previous"] = None
    else:
        if pagenum > 1:
            response["pagination"]["previous"] = f"/moviedata?pagenum={pagenum-1}&pagesize={pagesize}"
        else:
            response["pagination"]["previous"] = None

        response["pagination"]["next"] = f"/moviedata?pagenum={pagenum+1}&pagesize={pagesize}"
    #print(response)
    return response

@app.post("/input")
def recommend_movies(item: Item):
    print("start der recommendation")
    user_inputs_df = pd.DataFrame(item.ratings)
    df_ratings = ratings_df[["userId","movieId","rating"]].append(user_inputs_df)
    input_df = df_input.append(user_inputs_df)
    print(user_inputs_df)
    print(df_ratings)
    print(df_input)

    reader = Reader(rating_scale=(0.5, 5))
    data = Dataset.load_from_df(input_df, reader=reader)

    trainset = data.build_full_trainset()
    testset = trainset.build_anti_testset()

    algo_SVD = SVD(n_factors = 11)
    algo_SVD.fit(trainset)

    testset = trainset.build_anti_testset()
    predictions = algo_SVD.test(testset)

    user_id = item.ratings[0]["userId"]
    print(user_id)

    hist_usr, pred_usr = get_top_n(predictions=predictions, userId=user_id, movies_df=movies_df, ratings_df=df_ratings, n=10)
    print("ende der recommendation")
    print(type(pred_usr))
    recommendations = pred_usr.to_dict(orient='records')
    return recommendations

@app.post("/noinput")
def get_recommendations_from_id(userId: int):
    hist_usr, pred_usr = get_top_n(predictions, userId, movies_df, ratings_df, n = 10)
    recommendations = pred_usr.to_dict(orient='records')
    history = hist_usr.to_dict(orient='records')
    response = {
        "recommendations": recommendations,
        "history": history
    }
    print("------------------")
    print("------------------")
    print("history-dataframe")
    print(hist_usr)
    print("------------------")
    print("------------------")

    print("------------------")
    print("------------------")
    print("recommendations-dataframe")
    print(pred_usr)
    print("------------------")
    print("------------------")
    return response
