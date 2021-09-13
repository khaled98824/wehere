import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:location/location.dart';
import 'package:wehere/Data/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wehere/screens/home_test.dart';
import 'package:wehere/services/directions_model.dart';
import 'package:wehere/services/directions_repository.dart';
import 'package:wehere/services/polyline_services.dart';
import '../services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';

import 'location_tracking.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Map();
  }
}

class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  late StreamSubscription _locationSubscription;

  //late Location _locationTracker ;
  Marker? marker;

  Circle? circle;
  Completer<GoogleMapController> _controller = Completer();

  GoogleMapController? _googleMapController;

  LatLng currentLocation = _initialCameraPosition.target;
  Directions? _info;
  List<Polyline> myPolyLines = [];

  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(33.515343, 36.289590),
    zoom: 14.4746,
  );

  BitmapDescriptor? _locationIcon;

  Set<Marker> _markers = {};

  Set<Polyline> _polylines = {};

  @override
  void initState() {
    _buildMarkerFromAssets();
    super.initState();
    getmarkersFireStore();
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Map'),
        // actions: [
        //   IconButton(onPressed: _showSearchDialog, icon: Icon(Icons.search))
        // ],
        actions: [
          if (_origin != null)
            TextButton(
              onPressed: () => _googleMapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _origin!.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('ORIGIN'),
            ),
          if (_dist != null)
            TextButton(
              onPressed: () => _googleMapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _dist!.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('DEST'),
            )
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.hybrid,
            onMapCreated: (controller) => _googleMapController = controller,
            //     (controller) async {
            //   String style = await DefaultAssetBundle.of(context)
            //       .loadString('assets/map_style.json');
            //   //customize your map style at: https://mapstyle.withgoogle.com/
            //   controller.setMapStyle(style);
            //   _controller.complete(controller);
            // },
            onCameraMove: (e) => currentLocation = e.target,
            markers: {
              if (_origin != null) _origin!,
              if (_dist != null) _dist!,
            },
            // _markers,
            onLongPress: addMarker,
            polylines: myPolyLines.toSet(),
            //polylines: _polylines,
          ),
          //
          if (_info != null)
            Positioned(
              top: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6.0,
                    )
                  ],
                ),
                child: Text(
                  '${_info!.totalDistance}, ${_info!.totalDuration}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset('assets/images/location_icon.png'),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _drawPolyline(
                LatLng(38.52900208591146, -98.54919254779816), currentLocation),
            child: Icon(Icons.settings_ethernet_rounded),
          ),
          FloatingActionButton(
            onPressed: () => _setMarker(currentLocation),
            child: Icon(Icons.location_on),
          ),
          FloatingActionButton(
            onPressed: () => _getMyLocation(),
            child: Icon(Icons.gps_fixed),
          ),
//
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push( MaterialPageRoute(builder: (context)=> MapScreen()));
            },
            child: Icon(Icons.live_tv),
          ),
          //
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push( MaterialPageRoute(builder: (context)=> LocationTracking()));
            },
            child: Icon(Icons.trending_down_outlined),
          ),
          //
          FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.black,
            onPressed: () => _googleMapController!.animateCamera(
              _info != null
                  ? CameraUpdate.newLatLngBounds(_info!.bounds!, 100.0)
                  : CameraUpdate.newCameraPosition(_initialCameraPosition),
            ),
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 20,
        alignment: Alignment.center,
        child: Text(
            "lat: ${currentLocation.latitude}, long: ${currentLocation.longitude}"),
      ),
    );
  }

  //create poly
  createPolyLine() {
    myPolyLines.add(
      Polyline(
        polylineId: PolylineId('1'),
        color: Colors.blue,
        width: 3,
        points: [
          _dist!.position,
          _origin!.position,
        ],
      ),
    );
  }

  //
  Future<void> _drawPolyline(LatLng from, LatLng to) async {
    Polyline polyline = await PolylineService().drawPolyline(from, to);

    _polylines.add(polyline);

    _setMarker(from);
    _setMarker(to);

    setState(() {});
  }

//
  Marker? _origin;
  Marker? _dist;

  Future<void> addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _dist != null)) {
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );
        _dist = null;
        _info = null;
      });
    } else {
      setState(() {
        _dist = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Dest'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos,
        );
      });
      // Get directions

    }
    createPolyLine();
    print('or = $_origin  des = $_dist');
  }

  void _setMarker(LatLng _location) {
    print('_loc $_location');
    Marker newMarker = Marker(
      markerId: MarkerId(_location.toString()),
      icon: BitmapDescriptor.defaultMarker,
      // icon: _locationIcon,
      position: _location,
      infoWindow: InfoWindow(
          title: "Title",
          snippet: "${currentLocation.latitude}, ${currentLocation.longitude}"),
    );
    _markers.add(newMarker);
    setState(() {});
    var markers = FirebaseFirestore.instance.collection('markers');
    markers.doc().set({"lat": _markers.first.toJson()});
  }

  Future<void> getmarkersFireStore() async {
    List<DocumentSnapshot> newItems = [];
    LatLng latLng;
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("markers").get();
    final List<DocumentSnapshot> snap = querySnapshot.docs.toList();
    newItems = snap;
    latLng = newItems[0]['lat']['markerId'] as LatLng;
    // _markers.add(Marker(
    //   markerId: MarkerId(newItems[0]['lat']['markerId'] ),
    //   icon: BitmapDescriptor.defaultMarker,
    //   // icon: _locationIcon,
    //   position: newItems[0]['lat']['markerId'],
    //   infoWindow: InfoWindow(
    //       title: "Title",
    //       snippet: "${newItems[0]['lat']['position'][0]}, ${newItems[0]['lat']['position'][1]}"),
    // ));
    // newItems.forEach((element) {
    //   _markers.add(Marker(
    //     markerId: MarkerId(element['markerId']),
    //     icon: BitmapDescriptor.defaultMarker,
    //     // icon: _locationIcon,
    //     position: element['markerId'],
    //     infoWindow: InfoWindow(
    //         title: "Title",
    //         snippet: "${element['position'][0]}, ${element['position'][1]}"),
    //   ));
    // });
    print(_markers);
    setState(() {});
  }

  Future<void> _buildMarkerFromAssets() async {
    if (_locationIcon == null) {
      _locationIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration(size: Size(48, 48)),
          'assets/images/location_icon.png');
      setState(() {});
      print('icon set');
    }
  }

  Future<void> _showSearchDialog() async {
    var p = await PlacesAutocomplete.show(
        context: context,
        apiKey: Constants.apiKey,
        mode: Mode.fullscreen,
        language: "ar",
        region: "ar",
        offset: 0,
        hint: "Type here...",
        radius: 1000,
        types: [],
        strictbounds: false,
        components: [Component(Component.country, "ar")]);
    _getLocationFromPlaceId(p!.placeId!);
  }

  Future<void> _getLocationFromPlaceId(String placeId) async {
    GoogleMapsPlaces _places = GoogleMapsPlaces(
      apiKey: Constants.apiKey,
      apiHeaders: await GoogleApiHeaders().getHeaders(),
    );

    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);

    _animateCamera(LatLng(detail.result.geometry!.location.lat,
        detail.result.geometry!.location.lng));
  }

  Future<void> _getMyLocation() async {
    LocationData _myLocation = await LocationService().getCurrentLocation();
    _animateCamera(LatLng(_myLocation.latitude!, _myLocation.longitude!));
  }

  Future<void> _animateCamera(LatLng _location) async {
    final GoogleMapController? controller = await _controller.future;
    CameraPosition _cameraPosition = CameraPosition(
      target: _location,
      zoom: 13.00,
    );
    print(
        "animating camera to lat: ${_location.latitude}, long: ${_location.longitude}");
    controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
  }
}
