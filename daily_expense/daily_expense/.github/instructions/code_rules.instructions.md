---
applyTo: '**'
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.

This file is intended to be a reference for AI to understand the coding standards, architectural decisions, and any specific patterns or practices that are important for the project. It can include information about:
- Preferred programming languages and frameworks
- Code formatting and style guidelines
- Architectural patterns and design principles
- Testing strategies and tools
- Performance considerations
- Security best practices
- Any other relevant information that would help AI generate code that is consistent with the project's standards and practices.
By providing this context, you can help ensure that the AI-generated code aligns with the project's goals and maintains a high level of quality and consistency.

Prefered programming languages and frameworks:
- Flutter for mobile app development

Code formatting and style guidelines:
- Follow the Dart style guide for Flutter projects: https://dart.dev/guides/language/effective-dart/style
- Use 2 spaces for indentation
- Use camelCase for variable and function names
- Use PascalCase for class names
- Include documentation comments for public APIs
- Avoid using global variables and prefer dependency injection
- Use meaningful variable and function names that clearly indicate their purpose
- Keep functions and methods short and focused on a single task
- Use consistent naming conventions for files and directories
- Avoid deep nesting of code and prefer early returns to reduce complexity
- Use const and final where appropriate to indicate immutability
- Use async/await for asynchronous code and avoid using callbacks
- Write unit tests for critical code paths and use a testing framework like Flutter's built-in testing library
- Use version control and follow a consistent commit message format
- Regularly review and refactor code to maintain readability and performance
- Follow best practices for error handling and logging
- Ensure that the code is secure and follows best practices for data protection and privacy
- Optimize performance by avoiding unnecessary computations and using efficient algorithms
- Stay up to date with the latest Flutter and Dart updates and best practices to ensure that the codebase remains modern and maintainable.  

Architectural patterns and design principles:

- Follow the MVVM (Model-View-ViewModel) architectural pattern for Flutter applications
- Use Flutter's FilledStack for state management and dependency injection
- Use the Repository pattern to abstract data sources and promote separation of concerns
- Use dependency injection to manage dependencies and promote testability
- Separate concerns by organizing code into layers (e.g., presentation, domain, data)
- Use interfaces and abstract classes to define contracts and promote loose coupling
- Follow SOLID principles to create maintainable and scalable code
- Use design patterns like Factory, Singleton, and Observer where appropriate to solve common problems
- Avoid tight coupling between components and promote modularity
- Use reactive programming principles and streams for handling asynchronous data and events
- Implement error handling and logging in a consistent and centralized manner
- Use code reviews and pair programming to ensure code quality and knowledge sharing
- Regularly refactor code to improve readability, maintainability, and performance
- Stay up to date with the latest architectural patterns and design principles to ensure that the codebase remains modern and maintainable.

Testing strategies and tools:

- Write unit tests for critical code paths and use a testing framework like Flutter's built-in testing library
- Use mock objects and dependency injection to isolate code for testing
- Write integration tests to verify the interaction between different components
- Use end-to-end testing tools like Flutter Driver or integration_test for testing the entire application
- Follow the Arrange-Act-Assert (AAA) pattern for writing tests to improve readability and maintainability
- Use code coverage tools to ensure that critical code paths are adequately tested
- Regularly run tests and fix any failing tests to maintain a stable codebase
- Use continuous integration (CI) tools to automate testing and ensure that tests are run on every commit
- Stay up to date with the latest testing tools and best practices to ensure that the codebase remains modern and maintainable.

Performance considerations:

- Optimize performance by avoiding unnecessary computations and using efficient algorithms
- Use lazy loading and pagination to improve performance when dealing with large data sets
- Use caching strategies to reduce network calls and improve responsiveness
- Avoid blocking the main thread and use asynchronous programming to keep the UI responsive
- Use profiling tools to identify and address performance bottlenecks
- Optimize rendering performance by minimizing widget rebuilds and using const constructors where possible
- Use efficient data structures and algorithms to improve performance
- Avoid memory leaks by properly managing resources and using weak references where appropriate
- Regularly review and refactor code to improve performance and maintainability
- Stay up to date with the latest performance optimization techniques and best practices to ensure that the codebase remains modern and maintainable.

Security best practices:

- Follow best practices for data protection and privacy, such as encrypting sensitive data and using secure communication protocols
- Implement proper authentication and authorization mechanisms to protect user data and resources
- Use secure coding practices to prevent common vulnerabilities such as SQL injection, cross-site scripting (XSS), and cross-site request forgery (CSRF)
- Regularly update dependencies and libraries to address security vulnerabilities
- Use static code analysis tools to identify and fix security issues in the codebase
- Implement proper error handling and logging to avoid exposing sensitive information
- Use secure storage solutions for sensitive data, such as Flutter's secure storage plugin
- Educate developers on security best practices and promote a security-conscious culture within the team
- Regularly review and audit the codebase for security vulnerabilities and address any issues promptly
- Stay up to date with the latest security threats and best practices to ensure that the codebase remains secure and resilient against attacks.

Frontend development best practices:
- Use Flutter's widget tree effectively to create reusable and composable UI components
- Follow the principle of "separation of concerns" by keeping UI code separate from business logic
- Use Flutter's built-in widgets and libraries to create a consistent and native user experience
- Optimize UI performance by minimizing widget rebuilds and using const constructors where possible
- Use responsive design principles to ensure that the UI works well on different screen sizes and orientations
- Use DRY (Don't Repeat Yourself) principles to avoid code duplication and promote reusability
- Implement accessibility features to make the app usable for all users, including those with disabilities
- Use animations and transitions to enhance the user experience and provide visual feedback
- Follow platform-specific design guidelines (e.g., Material Design for Android, Cupertino for iOS) to create a native look and feel
- Use Flutter's testing tools to write UI tests and ensure that the user interface behaves as expected
- Use version control and follow a consistent commit message format to track changes to the UI code
- Use state management solutions like FilledStack to manage the state of the application effectively and promote separation of concerns
- Regularly review and refactor UI code to improve readability, maintainability, and performance
- Stay up to date with the latest Flutter updates and best practices to ensure that the codebase remains modern and maintainable.

FilledStack best practices:

- Use FilledStack for state management and dependency injection in Flutter applications
- Follow the MVVM (Model-View-ViewModel) architectural pattern when using FilledStack
- Make use of Models to represent the data and business logic of the application when using FilledStack
- Use ViewModels to manage the state and logic of the UI when using FilledStack
- Use Views to define the UI and bind it to the ViewModel when using FilledStack
- Based on the MVVM pattern, keep the ViewModel free of any UI code and focus on managing the state and logic of the application when using FilledStack
- Break the application into smaller, reusable components and use FilledStack to manage the state and dependencies of these components effectively
- Widgets should be as stateless as possible, with the state being managed by the ViewModel when using FilledStack
- Use all the features of FilledStack, such as dependency injection and reactive programming, to create a clean and maintainable codebase when using FilledStack
- Based on the requirement make use of vairous built-in base classes provided by FilledStack, such as BaseViewModel, BaseView, and BaseWidget, to simplify development and promote consistency when using FilledStack
- Use the built-in navigation and routing features of FilledStack to manage navigation in the application when using FilledStack
- Use the built-in error handling and logging features of FilledStack to manage errors and log important information in a consistent manner when using FilledStack
- Use the built-in testing features of FilledStack to write unit tests and ensure that the code behaves as expected when using FilledStack
- Contextualize the use of FilledStack based on the specific requirements of the application and choose the appropriate features and patterns to create a clean and maintainable codebase when using FilledStack
- Sharing context and passing data between different parts of the application can be done effectively using FilledStack's dependency injection and state management features when using FilledStack
- Use the Repository pattern to abstract data sources and promote separation of concerns when using FilledStack
- Use dependency injection to manage dependencies and promote testability when using FilledStack
- Use reactive programming principles and streams for handling asynchronous data and events when using FilledStack
- Implement error handling and logging in a consistent and centralized manner when using FilledStack
- Use code reviews and pair programming to ensure code quality and knowledge sharing when using FilledStack
- Regularly refactor code to improve readability, maintainability, and performance when using FilledStack
- Stay up to date with the latest FilledStack updates and best practices to ensure that the codebase remains modern and maintainable when using FilledStack.

Agent best practices:
- Use 