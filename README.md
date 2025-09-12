# Simple OAuth Server

## Summary

This document describes the software architecture of a simplified OAuth 2.0 authorization server implemented in Ruby on Rails. This server implements core OAuth 2.0 authorization code flow with PKCE (Proof Key for Code Exchange)
## Overview

### Purpose
The Simple OAuth Server is an OAuth 2.0 authorization server that:
- Issues authorization codes to client applications
- Exchanges authorization codes for access tokens  
- Authenticates access tokens for protected resource access
- Provides user information via a userinfo endpoint
- Handles user consent decisions for authorization requests
- Manages consent flow with allow/deny functionality


**OAuth 2.0 Authorization Code Flow ([RFC 6749 §4.1](https://tools.ietf.org/html/rfc6749#section-4.1))**
- **Justification**: Core OAuth flow considered most secure and widely adopted for web applications
- **Implementation**: Complete authorization endpoint (`/oauth/authorize`) and token endpoint (`/oauth/token`) following [RFC 6749 Section 4.1](https://tools.ietf.org/html/rfc6749#section-4.1) specification
- **Educational Value**: Demonstrates fundamental OAuth concepts including authorization codes, client authentication, and secure token exchange

**PKCE Implementation ([RFC 7636](https://tools.ietf.org/html/rfc7636))**
- **Justification**: Modern security best practice, mandatory in OAuth 2.1 draft, prevents authorization code interception attacks
- **Implementation**: Code challenge/verifier validation in both authorization and token endpoints as specified in [RFC 7636](https://tools.ietf.org/html/rfc7636)
- **Security Rationale**: Essential for public clients and recommended for all OAuth implementations per current security guidance

**Bearer Token Validation ([RFC 6750](https://tools.ietf.org/html/rfc6750))**
- **Justification**: Standard method for protecting resources with OAuth access tokens
- **Implementation**: `/oauth/userinfo` endpoint demonstrating proper bearer token authentication per [RFC 6750 Section 2.1](https://tools.ietf.org/html/rfc6750#section-2.1)
- **Practical Purpose**: Shows how resource servers validate tokens and serve protected data

**UserInfo Endpoint ([OpenID Connect Core 1.0 §5.3](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo))**
- **Justification**: Common OAuth use case providing standardized user profile access
- **Implementation**: Returns user profile information for valid access tokens, following [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) conventions
- **Integration Value**: Demonstrates complete OAuth flow from authorization through resource access

**Static Client Registration ([RFC 6749 §2](https://tools.ietf.org/html/rfc6749#section-2))**
- **Justification**: [RFC 6749 Section 2](https://tools.ietf.org/html/rfc6749#section-2) permits both dynamic and static client registration approaches
- **Implementation**: Database-managed client credentials and metadata
- **Simplification Rationale**: Avoids complexity of dynamic registration ([RFC 7591](https://tools.ietf.org/html/rfc7591)) while maintaining OAuth compliance

**Basic User Account Management (Application-Specific)**
- **Justification**: OAuth flows require user entities but don't specify user management implementation
- **Implementation**: Simple User model with basic profile information needed for OAuth flows
- **Scope Limitation**: Only user data necessary for OAuth demonstration, not comprehensive user management

**Basic User Account Management (Application-Specific)**
- **Justification**: OAuth flows require user entities but don't specify user management implementation
- **Implementation**: Simple User model with basic profile information needed for OAuth flows
- **Scope Limitation**: Only user data necessary for OAuth demonstration, not comprehensive user management

#### Out of Scope

**Full User Authentication UI ([RFC 6749 §3.1](https://tools.ietf.org/html/rfc6749#section-3.1) Simplification)**
- **Standard Requirement**: RFC 6749 Section 3.1 requires authorization server to authenticate resource owner through user interface
- **Educational Decision**: Replaced with `user_id` parameter to focus on OAuth rather than UI complexity
- **Production**: Real implementations require login forms, password validation, and session management

**Session Management and Logout ([RFC 6749 §4.1.3](https://tools.ietf.org/html/rfc6749#section-4.1.3) Omission)**
- **Standard Practice**: Production OAuth servers maintain user sessions and provide logout features
- **Project Limitation**: Stateless design prioritizes OAuth flow understanding over session complexity

**Token Refresh  ([RFC 6749 §6](https://tools.ietf.org/html/rfc6749#section-6) Omission)**
- **Standard Feature**: RFC 6749 Section 6 defines refresh token
- **Complexity Consideration**: Refresh tokens require additional complexity
- **Project Trade-off**: Fixed-lifetime access tokens simplify implementation

## Architecture Principles & Decisions

### Architectural Decisions


## System Architecture

### High-Level Architecture

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Rails Application                      │
├─────────────────────────────────────────────────────────────┤
│                      Controllers                           │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ OAuth           │  │ UserInfo        │                   │
│  │ Controller      │  │ Controller      │                   │
│  │ (/oauth/*)      │  │ (/oauth/       │                   │
│  │                 │  │  userinfo)      │                   │
│  └─────────────────┘  └─────────────────┘                   │
├─────────────────────────────────────────────────────────────┤
│                      Services                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │ Authorization   │  │ Token Request   │  │ Auth Code   │  │
│  │ Request         │  │ Validator       │  │ Validator   │  │
│  │ Validator       │  │                 │  │             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Models                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │ User            │  │ OauthClient     │  │ AccessToken │  │
│  │                 │  │                 │  │             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Data Storage                            │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ PostgreSQL      │  │ Redis           │                  │
│  │ (Persistent)    │  │ (Temporary)     │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

#### Authorization Endpoint
```
GET /oauth/authorize
```

**Purpose**: Initiates OAuth authorization flow  
**Parameters**:
- `client_id` (required): Registered client identifier
- `response_type` (required): Must be "code"
- `redirect_uri` (required): Client callback URL
- `user_id` (required): User identifier (simplified auth)
- `code_challenge` (required): PKCE code challenge
- `code_challenge_method` (required): Must be "S256"
- `state` (optional): Client state parameter

**Response**: JSON with redirect URL containing authorization code

#### Token Endpoint
```
POST /oauth/token
```

**Purpose**: Exchanges authorization code for access token  
**Parameters**:
- `grant_type` (required): Must be "authorization_code"
- `code` (required): Authorization code from authorize endpoint
- `client_id` (required): Client identifier
- `redirect_uri` (required): Must match authorization request
- `code_verifier` (required): PKCE code verifier

**Response**: JSON with access token and metadata

#### UserInfo Endpoint
```
GET /oauth/userinfo
```

**Purpose**: Returns user information for valid access token  
**Authentication**: Bearer token in Authorization header  
**Response**: JSON with user profile information

### Consent Flow Endpoints
**Purpose**: Provides consent information for user decision  


## Data Models

###  Relationship Diagram


### Components

#### Service Classes

**AuthorizationRequestValidator**
- Validates OAuth authorization parameters
- Ensures client exists and redirect URI matches
- Validates PKCE parameters

**TokenRequestValidator**
- Validates token exchange parameters
- Verifies authorization code
- Validates PKCE code verifier

**AuthorizationCodeValidator**
- Validates authorization codes
- Checks expiration and usage
- Performs PKCE verification

#### Models

**User**
- Represents resource owners
- Provides user information for userinfo endpoint
- Manages relationships with OAuth clients

**OauthClient**
- Represents registered client applications
- Stores client credentials and configuration
- Creates authorization codes and access tokens

**AccessToken**
- Represents issued access tokens
- Provides expiration checking
- Links users to client applications

## Flow Implementation

### Authorization Code Flow


### Consent Flow


### Test Coverage

- **Unit Tests**: Models and service classes
- **Integration Tests**: Controller endpoints
- **Security Tests**: PKCE validation, token authentication
- **Error Handling Tests**: Invalid parameters, expired tokens


### Deviations from Standards
