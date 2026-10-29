
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CajaHerramientasApp());
}

const morado = Colors.deepPurple;

class CajaHerramientasApp extends StatelessWidget {
  const CajaHerramientasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caja de Herramientas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: morado),
        useMaterial3: true,
      ),
      home: const InicioPage(),
    );
  }
}

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  static const herramientas = [
    {'nombre': 'Género por nombre', 'icono': Icons.person_search},
    {'nombre': 'Usuario aleatorio', 'icono': Icons.face},
    {'nombre': 'Universidades', 'icono': Icons.school},
    {'nombre': 'Clima en RD', 'icono': Icons.cloud},
    {'nombre': 'Pokémon', 'icono': Icons.catching_pokemon},
    {'nombre': 'Noticias WordPress', 'icono': Icons.article},
    {'nombre': 'Acerca de', 'icono': Icons.info},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja de Herramientas'),
        backgroundColor: morado,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.build_circle, size: 100, color: morado),
          const SizedBox(height: 10),
          const Text(
            'Mi Caja de Herramientas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Varias herramientas en una sola aplicación',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...herramientas.map((h) => Card(
                child: ListTile(
                  leading: Icon(h['icono'] as IconData,
                      color: morado, size: 30),
                  title: Text(h['nombre'] as String),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    final nombre = h['nombre'];
                    final Widget pagina;

                    switch (nombre) {
                      case 'Género por nombre':
                        pagina = const GeneroPage();
                        break;
                      case 'Usuario aleatorio':
                        pagina = const UsuarioPage();
                        break;
                      case 'Universidades':
                        pagina = const UniversidadesPage();
                        break;
                      case 'Clima en RD':
                        pagina = const ClimaPage();
                        break;
                      case 'Pokémon':
                        pagina = const PokemonPage();
                        break;
                      case 'Noticias WordPress':
                        pagina = const NoticiasPage();
                        break;
                      default:
                        pagina = const AcercaPage();
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => pagina),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }
}

// HERRAMIENTA 1: GENERO

class GeneroPage extends StatefulWidget {
  const GeneroPage({super.key});

  @override
  State<GeneroPage> createState() => _GeneroPageState();
}

class _GeneroPageState extends State<GeneroPage> {
  final nombreController = TextEditingController();
  String? genero;
  String? nombre;
  String? error;
  bool cargando = false;

  Future<void> consultar() async {
    final n = nombreController.text.trim();
    if (n.isEmpty) {
      setState(() => error = 'Escribe un nombre.');
      return;
    }

    setState(() {
      cargando = true;
      error = null;
      genero = null;
    });

    try {
      final r = await http.get(Uri.https(
          'api.genderize.io', '/', {'name': n}));
      if (r.statusCode != 200) throw Exception();

      final d = jsonDecode(r.body);
      if (!mounted) return;

      setState(() {
        genero = d['gender'];
        nombre = n;
        if (genero == null) error = 'No se pudo predecir el género.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Error de conexión.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masculino = genero == 'male';
    return Scaffold(
      appBar: AppBar(title: const Text('Género por nombre')),
      backgroundColor: genero == null
          ? Colors.white
          : masculino
              ? Colors.blue.shade100
              : Colors.pink.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 85,
                  color: masculino ? Colors.blue : Colors.pink),
              const Text('Predicción de género',
                  style: TextStyle(fontSize: 25,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => consultar(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: cargando ? null : consultar,
                child: const Text('Consultar género'),
              ),
              if (cargando) const CircularProgressIndicator(),
              if (genero != null) ...[
                const SizedBox(height: 20),
                Text(nombre!, style: const TextStyle(fontSize: 25)),
                Text(masculino ? 'Masculino' : 'Femenino',
                    style: TextStyle(
                      fontSize: 24,
                      color: masculino ? Colors.blue : Colors.pink,
                    )),
              ],
              if (error != null) Text(error!),
            ],
          ),
        ),
      ),
    );
  }
}

// HERRAMIENTA 2: USUARIO ALEATORIO

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  State<UsuarioPage> createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  Map<String, dynamic>? usuario;
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final r = await http.get(
          Uri.parse('https://randomuser.me/api/?results=1'));
      if (r.statusCode != 200) throw Exception();

      final d = jsonDecode(r.body);
      if (!mounted) return;

      setState(() {
        usuario = d['results'][0];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'No se pudo cargar el usuario.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Usuario aleatorio')),
      body: Center(
        child: cargando
            ? const CircularProgressIndicator()
            : error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!),
                      ElevatedButton(
                          onPressed: cargar,
                          child: const Text('Reintentar')),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 75,
                          backgroundImage:
                              NetworkImage(u!['picture']['large']),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${u['name']['first']} ${u['name']['last']}',
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.cake),
                          title: const Text('Fecha de nacimiento'),
                          subtitle: Text(
                            u['dob']['date'].toString().substring(0, 10),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Edad'),
                          subtitle: Text('${u['dob']['age']} años'),
                        ),
                        ElevatedButton.icon(
                          onPressed: cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generar otra persona'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// HERRAMIENTA 3: UNIVERSIDADES

class UniversidadesPage extends StatefulWidget {
  const UniversidadesPage({super.key});

  @override
  State<UniversidadesPage> createState() => _UniversidadesPageState();
}

class _UniversidadesPageState extends State<UniversidadesPage> {
  final paisController =
      TextEditingController(text: 'Dominican Republic');
  List<dynamic> universidades = [];
  bool cargando = false;
  String? error;

  Future<void> buscar() async {
    final pais = paisController.text.trim();
    if (pais.isEmpty) {
      setState(() => error = 'Escribe el país en inglés.');
      return;
    }

    setState(() {
      cargando = true;
      error = null;
      universidades = [];
    });

    try {
      final r = await http.get(Uri.https(
          'adamix.net', '/proxy.php', {'country': pais}));
      if (r.statusCode != 200) throw Exception();

      final dynamic d = jsonDecode(r.body);
      List<dynamic> lista;

      if (d is List) {
        lista = d;
      } else if (d is Map) {
        final contenido = d['universities'] ?? d['data'] ?? d['results'];
        if (contenido is! List) throw Exception();
        lista = contenido;
      } else {
        throw Exception();
      }

      if (!mounted) return;
      setState(() {
        universidades = lista;
        if (lista.isEmpty) error = 'No se encontraron universidades.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Error al cargar. Verifica el país.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String dato(dynamic u, List<String> claves) {
    if (u is Map) {
      for (final k in claves) {
        final v = u[k];
        if (v != null) return v is List ? v.join(', ') : v.toString();
      }
    }
    return 'No disponible';
  }

  Future<void> abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    paisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universidades')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: paisController,
                  decoration: const InputDecoration(
                    labelText: 'País en inglés',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => buscar(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: cargando ? null : buscar,
                  child: const Text('Buscar universidades'),
                ),
              ],
            ),
          ),
          if (cargando)
            const CircularProgressIndicator()
          else if (error != null)
            Text(error!)
          else
            Expanded(
              child: ListView.builder(
                itemCount: universidades.length,
                itemBuilder: (_, i) {
                  final u = universidades[i];
                  final nombre = dato(u, ['name', 'nombre']);
                  final dominio = dato(
                      u, ['domains', 'domain', 'dominio']);
                  final web = dato(
                      u, ['web_pages', 'web_page', 'website', 'url']);

                  return Card(
                    child: ListTile(
                      title: Text(nombre),
                      subtitle: Text('Dominio: $dominio\nWeb: $web'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: web.startsWith('http')
                            ? () => abrir(web.split(',').first.trim())
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// HERRAMIENTA 4: CLIMA DE REPUBLICA DOMINICANA

class ClimaPage extends StatefulWidget {
  const ClimaPage({super.key});

  @override
  State<ClimaPage> createState() => _ClimaPageState();
}

class _ClimaPageState extends State<ClimaPage> {
  Map<String, dynamic>? datos;
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarClima();
  }

  Future<void> cargarClima() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      // Coordenadas de Santo Domingo, República Dominicana.
      final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '18.4861',
        'longitude': '-69.9312',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'America/Santo_Domingo',
        'forecast_days': '1',
      });

      final r = await http.get(url);
      if (r.statusCode != 200) throw Exception();

      if (!mounted) return;
      setState(() => datos = jsonDecode(r.body));
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'No se pudo consultar el clima.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String descripcion(int codigo) {
    if (codigo == 0) return 'Despejado';
    if (codigo <= 3) return 'Parcialmente nublado';
    if (codigo <= 48) return 'Niebla';
    if (codigo <= 57) return 'Llovizna';
    if (codigo <= 67) return 'Lluvia';
    if (codigo <= 77) return 'Nieve';
    if (codigo <= 82) return 'Chubascos';
    if (codigo <= 86) return 'Chubascos de nieve';
    if (codigo <= 99) return 'Tormenta';
    return 'Condición desconocida';
  }

  @override
  Widget build(BuildContext context) {
    final actual = datos?['current'];
    final diario = datos?['daily'];

    return Scaffold(
      appBar: AppBar(title: const Text('Clima en RD')),
      body: Center(
        child: cargando
            ? const CircularProgressIndicator()
            : error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!),
                      ElevatedButton(
                          onPressed: cargarClima,
                          child: const Text('Reintentar')),
                    ],
                  )
                : datos == null
                    ? const Text('Sin información meteorológica.')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.wb_sunny,
                                size: 90, color: Colors.orange),
                            const Text(
                              'Santo Domingo, RD',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${actual['temperature_2m']} °C',
                              style: const TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(descripcion(actual['weather_code'])),
                            const SizedBox(height: 20),
                            ListTile(
                              leading: const Icon(Icons.thermostat),
                              title: const Text('Sensación térmica'),
                              subtitle: Text(
                                  '${actual['apparent_temperature']} °C'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.water_drop),
                              title: const Text('Humedad'),
                              subtitle: Text(
                                  '${actual['relative_humidity_2m']}%'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.air),
                              title: const Text('Viento'),
                              subtitle: Text(
                                  '${actual['wind_speed_10m']} km/h'),
                            ),
                            const Divider(),
                            const Text('Pronóstico para hoy',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('Fecha: ${diario['time'][0]}'),
                            Text('Máxima: ${diario['temperature_2m_max'][0]} °C'),
                            Text('Mínima: ${diario['temperature_2m_min'][0]} °C'),
                            Text('Probabilidad máxima de precipitación: '
                                '${diario['precipitation_probability_max'][0]}%'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: cargarClima,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar clima'),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

// HERRAMIENTA 5: POKEMON

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final nombreController = TextEditingController(text: 'pikachu');
  final reproductor = AudioPlayer();

  Map<String, dynamic>? pokemon;
  bool cargando = false;
  String? error;

  Future<void> buscarPokemon() async {
    final nombre = nombreController.text.trim().toLowerCase();

    if (nombre.isEmpty) {
      setState(() => error = 'Escribe el nombre de un Pokémon.');
      return;
    }

    setState(() {
      cargando = true;
      error = null;
      pokemon = null;
    });

    try {
      final r = await http.get(Uri.https(
          'pokeapi.co', '/api/v2/pokemon/$nombre'));
      if (r.statusCode != 200) {
        throw Exception('Pokémon no encontrado');
      }

      if (!mounted) return;
      setState(() => pokemon = jsonDecode(r.body));
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Pokémon no encontrado. Intenta otro nombre.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> reproducirSonido() async {
    final url = pokemon?['cries']?['latest'];
    if (url == null) {
      setState(() => error = 'Este Pokémon no tiene sonido disponible.');
      return;
    }

    try {
      await reproductor.stop();
      await reproductor.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'No se pudo reproducir el sonido.');
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    reproductor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = pokemon;
    final habilidades = p?['abilities'] as List?;

    return Scaffold(
      appBar: AppBar(title: const Text('Pokémon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.catching_pokemon,
                size: 65, color: Colors.red),
            const Text('Buscador Pokémon',
                style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Pokémon en inglés',
                hintText: 'pikachu',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => buscarPokemon(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cargando ? null : buscarPokemon,
                child: const Text('Buscar Pokémon'),
              ),
            ),
            if (cargando) const CircularProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (p != null) ...[
              const SizedBox(height: 20),
              Image.network(
                p['sprites']['other']['official-artwork']
                        ['front_default'] ??
                    p['sprites']['front_default'] ??
                    '',
                height: 190,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.catching_pokemon, size: 100),
              ),
              Text(
                p['name'].toString().toUpperCase(),
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Experiencia base'),
                  subtitle: Text(
                      '${p['base_experience'] ?? 'No disponible'} puntos'),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Habilidades',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...habilidades!.map((a) {
                        final habilidad = a['ability']['name'];
                        final oculta = a['is_hidden'] == true;
                        return ListTile(
                          leading: const Icon(Icons.flash_on),
                          title: Text(habilidad.toString()),
                          subtitle: oculta
                              ? const Text('Habilidad oculta')
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: reproducirSonido,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Reproducir sonido (latest)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// HERRAMIENTA 6: NOTICIAS WORDPRESS

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({super.key});

  @override
  State<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {
  // API publica de publicaciones de Kinsta.
  static const api =
      'https://kinsta.com/wp-json/wp/v2/posts'
      '?per_page=3&_fields=date,link,title,excerpt';

  List<dynamic> noticias = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final r = await http.get(Uri.parse(api));
      if (r.statusCode != 200) throw Exception();

      final d = jsonDecode(r.body);
      if (d is! List) throw Exception();

      if (!mounted) return;
      setState(() => noticias = d.take(3).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => error =
          'No se pudieron cargar las noticias. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String limpiarHtml(String texto) {
    return texto
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8230;', '...')
        .replaceAll('&quot;', '"')
        .trim();
  }

  Future<void> abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noticias WordPress')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(error!, textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                          onPressed: cargarNoticias,
                          child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarNoticias,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Image.network(
                        'https://kinsta.com/wp-content/uploads/2021/11/kinsta-logo.png',
                        height: 65,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.article, size: 65, color: morado),
                      ),
                      const Text(
                        'Últimas noticias de Kinsta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (noticias.isEmpty)
                        const Text('No hay noticias disponibles.')
                      else
                        ...noticias.map((n) {
                          final titulo =
                              limpiarHtml(n['title']['rendered'] ?? '');
                          final resumen =
                              limpiarHtml(n['excerpt']['rendered'] ?? '');
                          final link = n['link']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titulo,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(resumen.isEmpty
                                      ? 'Resumen no disponible.'
                                      : resumen),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: link.isEmpty
                                          ? null
                                          : () => abrir(link),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Visitar noticia'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const Text(
                        'Fuente: Kinsta',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// HERRAMIENTA 7: ACERCA DE

class AcercaPage extends StatelessWidget {
  const AcercaPage({super.key});

  // Coloca tu foto en assets/images/mi_foto.jpg
  // y configura ese archivo en pubspec.yaml.
  static const nombreCompleto = 'Jostin Wilmer Perez Santana';
  static const matricula = '2022-1096';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de mí')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/mi_foto.jpg'),
                
              ),
              const SizedBox(height: 20),
              const Text(
                nombreCompleto,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Estudiante de Desarrollo de Software'),
              const SizedBox(height: 8),
              const Text('Matrícula: $matricula'),
              const SizedBox(height: 24),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.code, color: morado),
                  title: Text('Área profesional'),
                  subtitle: Text('Desarrollo de software y programación'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.email, color: morado),
                  title: Text('Contacto'),
                  subtitle: Text(
                    'jostinwilmer@hotmail.com',
                  ),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.link, color: morado),
                  title: Text('Portafolio / GitHub'),
                  subtitle: Text(
                    'jjtana/github.com',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
