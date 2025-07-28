
## Implementation Plan
## Environment Setup
**Objective:** Set up the development environment for the Rails application.

**Action Steps:**.
- Create a new Github Repository for project
- Generate new Rails application and sync with github repo

## Research and Design
**Objective:** Research OAuth and design the authentication flow.

**Action Steps:**
- Review OAuth documentation and existing resources like SuperTokens.
- Outline the authentication flow, including login, token generation, and session management.

## Implement OAuth Interface
**Objective:** Start coding the OAuth interface.

**Action Steps:**
- Implement routes and controllers for OAuth authentication.
  - endpoints
    - /oauth/authorize - to get a code that is used to exchange for an access token
    - /oauth/token  - to exchange the code for an access token
  - 
- Ensure the ability to request user data (email, first name, last name) after authentication.

## Development and Testing

### Implement User
**Objective:** Set up user
- Implement User model and any relational setup needed
- Document user model structure on github

### Extend Session Management
**Objective:** Implement session extension and logout features.

**Action Steps:**
- Add functionality for extending user sessions.
- Implement a secure logout mechanism to invalidate tokens.
- Ensure session management adheres to best practices.

## Documentation and Code Review
**Objective:** Document the codebase and get feedback.

**Action Steps:**
- make sure all documentation is clear and comprehensive.
- Conduct a code review session with engineers in the team.
- Address any feedback and refine the code.

## Final Touches and Presentation

### Final Touches and Presentation Preparation
**Objective:** Prepare for the final presentation.

**Action Steps:**
- Prepare a presentation showcasing.
- Ensure all tickets reflect the work done.

### Final Presentation and Handover
**Objective:** Deliver the final presentation.

**Action Steps:**
- Present the project
- Discuss potential improvements.
