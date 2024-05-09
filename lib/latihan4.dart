import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart'
    as http; // Mengimpor package http untuk membuat HTTP requests.
import 'package:url_launcher/url_launcher.dart'; // Mengimpor package url_launcher untuk membuka URL.
import 'package:provider/provider.dart'; // Mengimpor package provider untuk manajemen state.

void main() {
  runApp(MyApp());
}

// Model untuk merepresentasikan data universitas.
class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  // Metode factory untuk membuat objek University dari JSON.
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'].isEmpty ? "" : json['web_pages'][0],
    );
  }
}

// Kelas model untuk state universitas.
class UniversityModel extends ChangeNotifier {
  List<University> _universities = []; // List universitas.

  List<University> get universities =>
      _universities; // Getter untuk list universitas.

  // Metode untuk mengambil data universitas dari API.
  Future<void> fetchUniversities(String country) async {
    try {
      final response = await http.get(Uri.parse(
          'http://universities.hipolabs.com/search?country=$country'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _universities = data
            .map((dynamic item) => University.fromJson(item))
            .toList(); // Mengisi list universitas dari response JSON.
        notifyListeners(); // Memberitahu listener bahwa state telah berubah.
      } else {
        throw Exception('Failed to load universities');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Membungkus aplikasi dengan ChangeNotifierProvider untuk manajemen state.
      create: (_) =>
          UniversityModel(), // Membuat instance dari UniversityModel.
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('ASEAN UNIVERSITIES'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CountryDropdown(), // Widget dropdown untuk memilih negara.
              SizedBox(height: 20),
              Expanded(
                  child:
                      UniversityList()), // Widget untuk menampilkan daftar universitas.
            ],
          ),
        ),
      ),
    );
  }
}

class CountryDropdown extends StatefulWidget {
  @override
  _CountryDropdownState createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  String dropdownValue = 'Indonesia'; // Nilai default dropdown.
  final List<String> countries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Vietnam'
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      onChanged: (String? newValue) {
        setState(() {
          dropdownValue =
              newValue!; // Mengubah nilai dropdown saat negara berubah.
        });
        final universityModel = Provider.of<UniversityModel>(context,
            listen: false); // Mendapatkan instance dari UniversityModel.
        universityModel.fetchUniversities(
            newValue!); // Memanggil metode untuk mengambil data universitas.
      },
      items: countries.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universityModel = Provider.of<UniversityModel>(
        context); // Mendapatkan instance dari UniversityModel.

    return ListView.builder(
      itemCount: universityModel.universities.length,
      itemBuilder: (context, index) {
        return UniversityTile(
            university: universityModel.universities[
                index]); // Widget untuk menampilkan tiap universitas.
      },
    );
  }
}

class UniversityTile extends StatelessWidget {
  final University university;

  UniversityTile({required this.university});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchURL(university.website); // Memanggil metode untuk membuka URL.
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              university.name,
              textAlign: TextAlign.center,
            ),
            subtitle: Text(
              university.website,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 0,
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isNotEmpty) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      throw 'URL is empty';
    }
  }
}
