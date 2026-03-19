List<Map<String, String>> MyData = [
  {
    'KhuPho': '1',
    'TongDien': '0 kwh',
    'TongNuoc': '0 m³',
  }

];void addKhuPho({
  required String khuPho,
  required String tongDien,
  required String tongNuoc,
}) {
  MyData.add({
    'KhuPho': khuPho,
    'TongDien': tongDien,
    'TongNuoc': tongNuoc,
  });
}
void removeKhuPho(String khuPho) {
  MyData.removeWhere((e) => e['KhuPho'] == khuPho);
}