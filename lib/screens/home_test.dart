import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? newMapController;
  Completer<GoogleMapController>? _controllerMap;
  GlobalKey<ScaffoldState>? scaffoldKey = new GlobalKey<ScaffoldState>();

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "Please provide your api key";
  CameraPosition? currentPosition;
  Set<Polyline>? polyLineSet;
  double bottomPaddOfMap = 0;
  var geoLocator =  Geolocator();


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          29.2559232, 47.9235764
      ),
    );
    return SafeArea(
      child: Scaffold(
          body: GoogleMap(
            initialCameraPosition: initialCameraPosition,
            myLocationEnabled: true,
            tiltGesturesEnabled: true,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            //onMapCreated: _onMapCreated,
            //markers: Set<Marker>.of(markers.values),
            polylines: Set<Polyline>.of(polylines.values),
          )),
    );
  }





  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }


}