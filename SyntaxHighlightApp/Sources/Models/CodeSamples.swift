import ShikiTokenSDK

/// A bundled source code example with its language identifier.
struct CodeSample: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let code: String
}

/// Predefined code samples for the demo app (Kotlin, Python, JSON, JavaScript).
enum CodeSamples {
    static let all: [CodeSample] = [kotlin, python, json, javascript]

    static let kotlin = CodeSample(
        id: "kotlin",
        name: "Kotlin",
        language: ShikiLanguage.kotlin,
        code: """
        import kotlinx.coroutines.*

        data class User(val name: String, val age: Int)

        suspend fun fetchUsers(): List<User> {
            return withContext(Dispatchers.IO) {
                listOf(
                    User("Alice", 30),
                    User("Bob", 25),
                    User("Charlie", 35)
                )
            }
        }

        fun main() = runBlocking {
            val users = fetchUsers()
            users.filter { it.age >= 30 }
                .forEach { println("${it.name} is ${it.age}") }
        }
        """
    )

    static let python = CodeSample(
        id: "python",
        name: "Python",
        language: ShikiLanguage.python,
        code: """
        import asyncio
        from dataclasses import dataclass

        @dataclass
        class User:
            name: str
            age: int

        async def fetch_users() -> list[User]:
            await asyncio.sleep(0.1)
            return [
                User("Alice", 30),
                User("Bob", 25),
                User("Charlie", 35),
            ]

        async def main():
            users = await fetch_users()
            for user in users:
                if user.age >= 30:
                    print(f"{user.name} is {user.age}")

        asyncio.run(main())
        """
    )

    static let json = CodeSample(
        id: "json",
        name: "JSON",
        language: ShikiLanguage.json,
        code: """
        {
          "users": [
            {
              "id": 1,
              "name": "Alice",
              "email": "alice@example.com",
              "roles": ["admin", "user"]
            },
            {
              "id": 2,
              "name": "Bob",
              "email": "bob@example.com",
              "roles": ["user"]
            }
          ],
          "metadata": {
            "total": 2,
            "page": 1
          }
        }
        """
    )

    static let javascript = CodeSample(
        id: "javascript",
        name: "JavaScript",
        language: ShikiLanguage.javascript,
        code: """
        class UserService {
          constructor(baseUrl) {
            this.baseUrl = baseUrl;
          }

          async fetchUsers() {
            const response = await fetch(`${this.baseUrl}/users`);
            if (!response.ok) {
              throw new Error(`HTTP ${response.status}`);
            }
            return response.json();
          }

          async getUserById(id) {
            const users = await this.fetchUsers();
            return users.find(user => user.id === id);
          }
        }

        const service = new UserService("https://api.example.com");
        service.fetchUsers().then(users => console.log(users));
        """
    )
}
