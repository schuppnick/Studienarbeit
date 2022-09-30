import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recommender System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Studienarbeit: Recommender-System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _loadedMovies = [];
  Map _loadedData = {};
  List _recommendations = [];
  List _selectedMoviesId = [];
  List _selectedMoviesTitle = [];
  List _ratingsControllerList = [];

  TextEditingController userIdController = TextEditingController();

  final apiPostUrl = 'http://127.0.0.1:8000/input';
  final apiPostUrl2 = 'http://127.0.0.1:8000/noinput';

  Future<void> _fetchMovieData() async {
    const apiGetUrl = 'http://127.0.0.1:8000/moviedata';
    final response = await http.get(Uri.parse(apiGetUrl));
    final data = json.decode(response.body);

    setState(() {
      _loadedData = data;
      _loadedMovies = data['movie_data'];
    });

    //print(data['movie_data']);
  }

  List<Widget> _selectedMovies = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _loadedMovies.isEmpty
            ? Center(
          child: ElevatedButton(
            onPressed: _fetchMovieData,
            child: const Text('Load Data'),
          ),
        )
        // The ListView that displays photos
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                      flex: 6,
                      child: Container(
                          color: Colors.blue,
                          child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 15,
                              child: ListView.separated(
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.black,
                                ),
                            itemCount: _selectedMovies.length,
                            itemBuilder: (context, index) => _selectedMovies[index],
                        ))),
                      ),
                  Expanded(
                      flex: 1,
                      child: Container(
                        //alignment: Alignment.center,
                        color: Colors.blue,
                        child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 15,
                            child: Center(child: ListTile(
                              leading: ElevatedButton(
                                style: ButtonStyle(
                                    foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.purple)),
                                child: const Text('Clear'),
                                onPressed: () {
                                  setState(() {
                                    _selectedMovies = [];
                                    _recommendations = [];
                                  });
                                },
                              ),
                          title:
                            ElevatedButton(
                              style: ButtonStyle(
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.purple)),
                              onPressed: () async {
                                double rating;
                                int id;
                                String title;
                                if(_selectedMovies.isEmpty) {
                                  var userId = userIdController.text;
                                  var response = await http.post(
                                      Uri.parse(apiPostUrl2 + '?userId=' + userId), body: json.encode(
                                      userId));
                                  var result = json.decode(response.body);
                                  setState(() {
                                    _recommendations = result["recommendations"];
                                    for(int i = 0; i < result["history"].length; i++) {
                                      _selectedMovies.add(ListTile(
                                        leading: Text(result["history"][i]["movieId"].toString()),
                                        title: Text(result["history"][i]["title"]),
                                        subtitle: Text(result["history"][i]["genres"]),
                                        trailing: Text(
                                            result["history"][i]["rating"].toString()
                                        ),
                                      ));
                                    }
                                  });
                                }
                                else {
                                  List movieInputs = [];
                                  var userId = userIdController.text;

                                  for (int i = 0; i <
                                      _selectedMovies.length; i++) {
                                    rating = double.parse(
                                        _ratingsControllerList[i].text);
                                    id = _selectedMoviesId[i];
                                    title = _selectedMoviesTitle[i];

                                    Map movieEntry = {
                                      "userId": userId,
                                      "movieId": id,
                                      "rating": rating
                                    };
                                    movieInputs.add(movieEntry);
                                  }
                                  var response = await http.post(
                                      Uri.parse(apiPostUrl), body: json.encode(
                                      {"ratings": movieInputs}),
                                      headers: {
                                        'content-type': 'application/json'
                                      });
                                  setState(() {
                                    _recommendations =
                                        json.decode(response.body);
                                  });
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          trailing: Container(
                            width: 100,
                            height: 40,
                            child: TextField(
                              controller: userIdController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "userId",
                              ),
                            ),
                          ),
                        ))),
                      )),
                  Expanded(
                      flex: 6,
                      child: Container(
                        color: Colors.blue,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 15,
                          child: ListView.separated(
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.black,
                              ),
                          itemCount: _recommendations.length,
                          itemBuilder: (BuildContext context, index) {
                            return ListTile(
                              leading: Text(_recommendations[index]["movieId"].toString()),
                              title: Text(_recommendations[index]["title"].toString()),
                              subtitle: Text(_recommendations[index]["genres"]),
                              trailing: Text(_recommendations[index]["rat_pred"].toString()),
                            );
                          }
                        ),
                      )))
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  Expanded(
                      flex: 11,
                      child: Container(
                          color: Colors.blue,
                          child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 15,
                              child: ListView.separated(
                                  separatorBuilder: (context, index) => Divider(
                                    color: Colors.black,
                                  ),
                                itemCount: _loadedMovies.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return ListTile(
                                    leading:
                                    Text(_loadedMovies[index]["movieId"].toString()),
                                    title:
                                    Text(_loadedMovies[index]["title"]),
                                    subtitle: Text(_loadedMovies[index]["genres"]),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.favorite_border,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        setState(
                                              () {
                                                TextEditingController ratingsController = new TextEditingController();
                                                _ratingsControllerList.add(ratingsController);
                                                _selectedMoviesId.add(_loadedMovies[index]["movieId"]);
                                                _selectedMoviesTitle.add(_loadedMovies[index]["title"]);
                                            _selectedMovies.add(
                                              ListTile(
                                                leading: Text(_loadedMovies[index]["movieId"].toString()),
                                                title: Text(_loadedMovies[index]["title"]),
                                                subtitle: Text(_loadedMovies[index]["genres"]),
                                                trailing: Container(
                                                  height: 40,
                                                  width: 100,
                                                  child: TextField(
                                                    controller: ratingsController,
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      labelText: "Rating",
                                                    ),
                                                  ),
                                                ),
                                              )
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                              })))),
                  Expanded(
                    flex: 1,
                    child: Container(
                        color: Colors.blue,
                        child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 15,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                                child: (_loadedData["pagination"]["previous"] == null) ? Text("") : IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_left,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    var apiGetUrl = 'http://127.0.0.1:8000' + _loadedData["pagination"]["previous"];
                                    var response = await http.get(Uri.parse(apiGetUrl));
                                    var data = json.decode(response.body);
                                    setState(() {
                                      _loadedData = data;
                                      _loadedMovies = data['movie_data'];
                                    });
                                  },
                                )),
                            Expanded(
                                flex: 1,
                                child: Container(
                                    child: Center(
                                        child: Text(
                                            _loadedData["page"].toString()
                                        )
                                    )
                                )
                            ),
                            Expanded(
                                flex: 1,
                                child: (_loadedData["pagination"]["next"] == null) ? Text("") : IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_right,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    var apiGetUrl = 'http://127.0.0.1:8000' + _loadedData["pagination"]["next"];
                                    var response = await http.get(Uri.parse(apiGetUrl));
                                    var data = json.decode(response.body);
                                    setState(() {
                                      _loadedData = data;
                                      _loadedMovies = data['movie_data'];
                                    });
                                  },
                                ))
                          ],
                    ))),
                  )
                ],
              ),
            ),
          ],
        ));
  }
}
