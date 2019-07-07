import 'package:example/app.route.dart';
import 'package:flutter/material.dart';
import 'package:route_annotation/route_annotation.dart';

@RoutePage(isInitialRoute: true)
class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          children: <Widget>[
            Text("FirstPage"),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ROUTE_SECOND_PAGE);
              },
              child: Text("Next Page"),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ROUTE_ALIAS_FUN);
              },
              child: Text("Go to Alias Page"),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ROUTE_CUSTOM);
              },
              child: Text("Go to CustomRouteName Page"),
            ),
          ],
        ),
      ),
    );
  }
}
