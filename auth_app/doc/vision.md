This project focuses on building a secure, end-to-end authentication system using Flutter and Supabase, structured entirely around Clean Architecture principles for maintainability and scale.

Core User Flows

Registration & Login: Dual-method support utilizing either Email/Password + OTP or Phone Number/Password + OTP.

Credential Management: Complete "Forgot Password" recovery flow and a post-login "Reset Password" feature.

Technical Stack & Implementation

Backend: Supabase (handling auth state, OTP generation, and user management).

Architecture: Clean Architecture (separating data, domain, and presentation layers).

State Management: BLoC.

Routing: GoRouter.

Dependency Injection: GetIt.

UI/UX: Integration of a high-quality design and animation library to deliver smooth, polished interactions across the auth screens.