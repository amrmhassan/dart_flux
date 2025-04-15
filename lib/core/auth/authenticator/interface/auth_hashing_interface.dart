abstract class AuthHashingInterface {
  Future<String> hash(String plain);
  Future<bool> verify(String plain, String hashed);
}
