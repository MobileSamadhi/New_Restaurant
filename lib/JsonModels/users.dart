//In here first we create the users json model
// To parse this JSON data, do
//user.dart

class Users {
final int? usrId;
final String usrName;
final String usrPassword;
final String? usrPhone;

Users({
this.usrId,
required this.usrName,
required this.usrPassword,
  this.usrPhone,
});

factory Users.fromMap(Map<String, dynamic> json) => Users(
usrId: json["usrId"],
usrName: json["usrName"],
usrPassword: json["usrPassword"],
  usrPhone: json["usrPhone"],
);

Map<String, dynamic> toMap() => {
"usrId": usrId,
"usrName": usrName,
"usrPassword": usrPassword,
  "usrPhone": usrPhone,
};
}
