import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/listings/presentation/screens/listing_detail_screen.dart';
import '../../features/listings/presentation/screens/create_listing_screen.dart';
import '../../features/listings/presentation/screens/edit_listing_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/seller/presentation/screens/seller_dashboard_screen.dart';
import '../../features/requests/presentation/screens/requests_screen.dart';
import '../../features/messages/presentation/screens/conversations_screen.dart';
import '../../features/messages/presentation/screens/chat_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => SearchScreen(
              initialQuery: state.uri.queryParameters['q'],
              initialCategory: state.uri.queryParameters['category'],
            ),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      // IMPORTANT: static routes (/create) must come BEFORE dynamic (:id)
      // so GoRouter does not match "create" as a listing ID.
      GoRoute(
        path: '/listings/create',
        name: 'createListing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listings/:id/edit',
        name: 'editListing',
        builder: (context, state) => EditListingScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/listings/:id',
        name: 'listingDetail',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/seller/dashboard',
        name: 'sellerDashboard',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
          otherUserName: state.uri.queryParameters['name'] ?? 'User',
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'userProfile',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
