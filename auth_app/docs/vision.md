This project focuses on building a secure, end-to-end authentication system using Flutter and Supabase, structured entirely around Clean Architecture principles for maintainability and scale.

Core User Flows

Registration & Login: Dual-method support utilizing either Email/Password with an email confirmation link (the user signs in after confirming) or Phone Number/Password with a temporary stub OTP step (fixed code, no SMS) until a real SMS provider is added.

Credential Management: Complete "Forgot Password" recovery flow and a post-login "Reset Password" feature.

Technical Stack & Implementation

Backend: Supabase (handling auth state and user management; email confirmation links; no SMS OTP for now).

Architecture: Clean Architecture (separating data, domain, and presentation layers).

State Management: BLoC.

Routing: GoRouter.

Dependency Injection: GetIt.

UI/UX: Integration of a high-quality design and animation library to deliver smooth, polished interactions across the auth screens.