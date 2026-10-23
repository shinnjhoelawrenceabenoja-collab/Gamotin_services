class User {
  final int id;
  final String name, phone, email, role;
  User(this.id, this.name, this.phone, this.email, this.role);
  factory User.fromJson(Map<String, dynamic> j) =>
      User(j['id'], j['name'], j['phone'] ?? '', j['email'], j['role'] ?? 'client');
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'phone': phone, 'email': email, 'role': role};
}

class OrderFile {
  final int id, size;
  final String filename;
  OrderFile(this.id, this.filename, this.size);
}

class Order {
  final int id, copies;
  final bool color, duplex;
  final String paperSize, paperType, pageRange, notes, status;
  final DateTime createdAt;
  final List<OrderFile> files;
  Order.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        copies = j['copies'],
        color = j['color'],
        duplex = j['duplex'],
        paperSize = j['paper_size'],
        paperType = j['paper_type'],
        pageRange = j['page_range'] ?? '',
        notes = j['notes'] ?? '',
        status = j['status'],
        createdAt = DateTime.parse(j['created_at']).toLocal(),
        files = (j['files'] as List)
            .map((f) => OrderFile(f['id'], f['filename'], f['size']))
            .toList();
}
