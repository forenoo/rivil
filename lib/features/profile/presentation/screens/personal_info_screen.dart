import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Informasi Pribadi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          color: colorScheme.primary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileAvatar(context),
                const SizedBox(height: 20),
                Text(
                  'Informasi Dasar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoItem(
                  context: context,
                  label: 'Nama Lengkap',
                  value: 'John Doe',
                  icon: Icons.person_outline_rounded,
                ),
                _buildInfoItem(
                  context: context,
                  label: 'Username',
                  value: '@johndoe',
                  icon: Icons.alternate_email_rounded,
                ),
                _buildInfoItem(
                  context: context,
                  label: 'Email',
                  value: 'john.doe@example.com',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                Text(
                  'Kontak',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoItem(
                  context: context,
                  label: 'Nomor Telepon',
                  value: '+62 812 3456 7890',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 20),
                Text(
                  'Alamat',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoItem(
                  context: context,
                  label: 'Alamat Lengkap',
                  value: 'Jl. Sudirman No. 123, Jakarta Pusat',
                  icon: Icons.location_on_outlined,
                ),
                _buildInfoItem(
                  context: context,
                  label: 'Kota',
                  value: 'Jakarta',
                  icon: Icons.location_city_outlined,
                ),
                _buildInfoItem(
                  context: context,
                  label: 'Kode Pos',
                  value: '10210',
                  icon: Icons.markunread_mailbox_outlined,
                ),
                const SizedBox(height: 20),
                _buildEditButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    String? avatarUrl;

    if (session != null) {
      final userData = session.user.userMetadata;
      if (userData != null) {
        avatarUrl = userData['avatar_url'];
      }
    }

    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl) as ImageProvider
                  : const AssetImage('assets/images/avatar_fallback.png'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Handle avatar update
            },
            icon: Icon(
              Icons.photo_camera_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'Ubah Foto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to edit profile screen
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Edit Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
