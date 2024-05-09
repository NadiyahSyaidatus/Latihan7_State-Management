import 'package:flutter/material.dart';
import 'dart:convert'; // Mengimpor dart:convert untuk mendekode JSON
import 'package:http/http.dart'
    as http; // Mengimpor paket http untuk melakukan permintaan HTTP
import 'package:url_launcher/url_launcher.dart'; // Mengimpor paket url_launcher untuk meluncurkan URL
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor flutter_bloc untuk manajemen status

void main() {
  runApp(MyApp());
}

// Kelas University untuk merepresentasikan data universitas
class University {
  final String name; // Nama universitas
  final String website; // URL situs web universitas

  // Konstruktor
  University({required this.name, required this.website});

  // Metode factory untuk membuat objek University dari data JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'].isEmpty ? "" : json['web_pages'][0],
    );
  }
}

// Kelas UniversityCubit untuk mengelola status data universitas menggunakan pola BLoC
class UniversityCubit extends Cubit<List<University>> {
  UniversityCubit() : super([]); // Status awal adalah list kosong
  // Metode untuk mengambil data universitas berdasarkan negara
  void fetchUniversities(String country) async {
    try {
      final response = await http.get(Uri.parse(
          'http://universities.hipolabs.com/search?country=$country'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<University> universities =
            data.map((dynamic item) => University.fromJson(item)).toList();
        emit(universities); // Mengeluarkan status universitas
      } else {
        throw Exception('Gagal memuat data universitas');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server.');
    }
  }
}

// MyApp adalah kelas utama aplikasi Flutter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => UniversityCubit(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('ASEAN UNIVERSITIES'), // Judul AppBar
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  height: 20), // Jarak antara dropdown dan daftar universitas
              CountryDropdown(), // Menampilkan dropdown negara
              SizedBox(
                  height: 20), // Jarak antara dropdown dan daftar universitas
              Expanded(
                  child: UniversityList()), // Menampilkan daftar universitas
            ],
          ),
        ),
      ),
    );
  }
}

// CountryDropdown adalah widget untuk menampilkan dropdown negara
class CountryDropdown extends StatefulWidget {
  @override
  _CountryDropdownState createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  late String dropdownValue; // Nilai dropdown yang dipilih

  final List<String> countries = [
    // Daftar negara ASEAN
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Vietnam'
  ];

  @override
  void initState() {
    super.initState();
    dropdownValue = countries[0]; // Nilai dropdown awal
  }

  @override
  Widget build(BuildContext context) {
    final universityCubit = BlocProvider.of<UniversityCubit>(context);

    return BlocBuilder<UniversityCubit, List<University>>(
      builder: (context, state) {
        return DropdownButton<String>(
          value: dropdownValue, // Nilai dropdown yang dipilih
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!; // Mengubah nilai dropdown yang dipilih
            });
            universityCubit.fetchUniversities(
                newValue!); // Memuat universitas berdasarkan negara yang dipilih
          },
          items: countries.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                  value), // Menampilkan nama negara sebagai pilihan dropdown
            );
          }).toList(),
        );
      },
    );
  }
}

// UniversityList adalah widget untuk menampilkan daftar universitas
class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universityCubit = BlocProvider.of<UniversityCubit>(context);

    return BlocBuilder<UniversityCubit, List<University>>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.length,
          itemBuilder: (context, index) {
            return UniversityTile(
                university: state[index]); // Menampilkan tile universitas
          },
        );
      },
    );
  }
}

// UniversityTile adalah widget untuk menampilkan detail universitas dalam bentuk tile
class UniversityTile extends StatelessWidget {
  final University university;

  UniversityTile({required this.university});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchURL(
            university.website); // Meluncurkan URL universitas saat tile diklik
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              university.name, // Menampilkan nama universitas
              textAlign: TextAlign.center,
            ),
            subtitle: Text(
              university.website, // Menampilkan URL situs web universitas
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue, // Warna teks biru
                decoration: TextDecoration.underline, // Garis bawah
              ),
            ),
          ),
          Divider(
            color: Colors.grey[300], // Warna garis abu-abu
            thickness: 1,
            height: 0,
          ),
        ],
      ),
    );
  }

  // Metode untuk meluncurkan URL
  Future<void> _launchURL(String url) async {
    if (url.isNotEmpty) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Tidak dapat meluncurkan $url';
      }
    } else {
      throw 'URL kosong';
    }
  }
}
