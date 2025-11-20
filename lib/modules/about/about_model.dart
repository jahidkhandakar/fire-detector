class AboutContact {
  final String address;
  final String phone;
  final String website;
  final String facebook;
  final String linkedin;

  AboutContact({
    required this.address,
    required this.phone,
    required this.website,
    required this.facebook,
    required this.linkedin,
  });

  factory AboutContact.fromJson(Map<String, dynamic> json) {
    return AboutContact(
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      facebook: (json['facebook'] ?? '').toString(),
      linkedin: (json['linkedin'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'phone': phone,
        'website': website,
        'facebook': facebook,
        'linkedin': linkedin,
      };
}

class AboutModel {
  final String company;
  final String overview;
  final AboutContact contact;

  AboutModel({
    required this.company,
    required this.overview,
    required this.contact,
  });

  factory AboutModel.fromJson(Map<String, dynamic> json) {
    return AboutModel(
      company: (json['company'] ?? '').toString(),
      overview: (json['overview'] ?? '').toString(),
      contact: AboutContact.fromJson(
        Map<String, dynamic>.from(json['contact'] ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'overview': overview,
        'contact': contact.toJson(),
      };
}
