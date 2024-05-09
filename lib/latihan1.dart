import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Mengimpor package untuk menangani pembukaan URL.
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor package Flutter Bloc untuk manajemen state.
import 'package:equatable/equatable.dart'; // Mengimpor package Equatable untuk membuat objek perbandingan yang mudah.

void main() {
  runApp(MyApp());
}

// Kelas model untuk merepresentasikan data universitas.
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

// Event untuk memicu fetch universitas.
class FetchUniversities extends Equatable {
  final String country;

  FetchUniversities(this.country);

  @override
  List<Object?> get props => [country];
}

// State untuk menampung data universitas.
class UniversityState extends Equatable {
  final List<University> universities;
  final String
      selectedCountry; // Menambah properti untuk menyimpan negara yang dipilih.

  UniversityState(this.universities, {required this.selectedCountry});

  @override
  List<Object?> get props => [universities, selectedCountry];
}

// BLoC untuk mengelola data universitas.
class UniversityBloc extends Bloc<FetchUniversities, UniversityState> {
  UniversityBloc()
      : super(UniversityState([],
            selectedCountry: 'Indonesia')); // Inisialisasi negara default.

  @override
  Stream<UniversityState> mapEventToState(FetchUniversities event) async* {
    try {
      final response = await http.get(Uri.parse(
          'http://universities.hipolabs.com/search?country=${event.country}'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<University> universities =
            data.map((dynamic item) => University.fromJson(item)).toList();
        yield UniversityState(universities,
            selectedCountry: event
                .country); // Update state dengan negara yang dipilih dari event.
      } else {
        throw Exception('Failed to load universities');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }
}

// Widget utama aplikasi.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) =>
            UniversityBloc(), // Membuat instance dari UniversityBloc.
        child: Scaffold(
          appBar: AppBar(
            title: Text('ASEAN UNIVERSITIES'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CountryDropdown(), // Menampilkan dropdown negara.
              SizedBox(height: 20),
              Expanded(
                  child: UniversityList()), // Menampilkan daftar universitas.
            ],
          ),
        ),
      ),
    );
  }
}

// Widget dropdown untuk memilih negara.
class CountryDropdown extends StatelessWidget {
  final List<String> countries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Vietnam'
  ];

  @override
  Widget build(BuildContext context) {
    final universityBloc = BlocProvider.of<UniversityBloc>(context);

    return BlocBuilder<UniversityBloc, UniversityState>(
      builder: (context, state) {
        return DropdownButton<String>(
          value: state
              .selectedCountry, // Menggunakan negara yang dipilih dari state UniversityBloc.
          onChanged: (String? newValue) {
            universityBloc.add(FetchUniversities(
                newValue!)); // Memperbarui negara yang dipilih saat dipilih dari dropdown.
          },
          items: countries.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }
}

// Widget untuk menampilkan daftar universitas.
class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universityBloc = BlocProvider.of<UniversityBloc>(context);

    return BlocBuilder<UniversityBloc, UniversityState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.universities.length,
          itemBuilder: (context, index) {
            return UniversityTile(university: state.universities[index]);
          },
        );
      },
    );
  }
}

// Widget untuk menampilkan tiap universitas dalam daftar.
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

  // Metode untuk membuka URL.
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
