import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/about/about_controller.dart';
import '/others/utils/api.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final AboutController _aboutCtrl = Get.put(AboutController());
  final String apiUrl = Api.about;

  @override
  void initState() {
    super.initState();
    _aboutCtrl.loadAbout(apiUrl: apiUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Obx(() {
        if (_aboutCtrl.isLoading.value && _aboutCtrl.about.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_aboutCtrl.error.value.isNotEmpty &&
            _aboutCtrl.about.value == null) {
          return _error(_aboutCtrl.error.value);
        }

        final data = _aboutCtrl.about.value;
        if (data == null)
          return const Center(child: Text('No information available.'));

        final contact = data.contact;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: Colors.deepOrange,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 16,
                ),
                title: Text(
                  data.company,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .5,
                    color: Colors.white,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/icons/apsLogo.png',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Center(
                            child: Text(
                              'Image not found',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    ),
                    // Semi-transparent gradient overlay so image stays visible
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF7043).withOpacity(0.65),
                            const Color(0xFFFFA040).withOpacity(0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Opacity(
                          opacity: .15,
                          child: Icon(
                            Icons.local_fire_department,
                            size: 140,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //---------------- Overview Section ------------------//
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading('Overview'),
                      const SizedBox(height: 8),
                      Text(
                        data.overview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //---------------- Contact Section ------------------//
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading('Contact'),
                      const SizedBox(height: 12),
                      _contactTile(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: contact.address,
                      ),
                      _divider(),
                      _contactTile(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: contact.phone,
                        onTap: _launchIf('tel:${contact.phone}'),
                      ),
                      _divider(),
                      _contactTile(
                        icon: Icons.language,
                        label: 'Website',
                        value: contact.website,
                        onTap: _launchIf(contact.website),
                      ),
                      _divider(),
                      _contactTile(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        value: contact.facebook,
                        onTap: _launchIf(contact.facebook),
                      ),
                      _divider(),
                      _contactTile(
                        icon: Icons.business_center,
                        label: 'LinkedIn',
                        value: contact.linkedin,
                        onTap: _launchIf(contact.linkedin),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //------------------Footer Section ------------------//
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverToBoxAdapter(
                child: Opacity(
                  opacity: .7,
                  child: Text(
                    '© ${DateTime.now().year} ${data.company}. All rights reserved.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  //*__________________________WIDGETS__________________________*//
  Widget _error(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(msg, style: const TextStyle(color: Colors.red)),
    ),
  );

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: child,
      ),
    );
  }

  Widget _heading(String text, {TextStyle? style}) => Text(
    text,
    style:
        style ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
          color: Colors.deepOrange,
        ),
  );

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepOrange.withOpacity(.12),
              child: Icon(icon, color: Colors.deepOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.open_in_new, size: 18, color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 22, thickness: .7);

  VoidCallback? _launchIf(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    return () async {
      final uri = Uri.tryParse(
        trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
      );
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    };
  }
}
