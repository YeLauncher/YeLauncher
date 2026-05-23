class MinecraftProfileModel {
  final String nickname;
  final String uuid;
  final String accessToken;
  final String userType;

  MinecraftProfileModel({
    required this.nickname,
    required this.uuid,
    required this.accessToken,
    required this.userType,
  });

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'uuid': uuid,
    'access_token': accessToken,
    'user_type': userType,
  };

  factory MinecraftProfileModel.fromJson(Map<String, dynamic> json) => MinecraftProfileModel(
    nickname: json['nickname'] as String,
    uuid: json['uuid'] as String,
    accessToken: json['access_token'] as String,
    userType: json['user_type'] as String,
  );
}