# db/seeds.rb
# Idempotent System Authorization Seeding
# Establishes canonical global system roles, global permissions, and role-permission mappings.

ActiveRecord::Base.transaction do
  # 1. Canonical System Roles (Global, tenant_id: nil)
  system_roles_data = [
    {
      key: "super_admin",
      name: "Super Admin",
      description: "Platform Super Administrator with unrestricted system access and tenant management capabilities"
    },
    {
      key: "branch_admin",
      name: "Branch Admin",
      description: "Franchise Branch Administrator managing center operations, staff, students, and finances"
    },
    {
      key: "trainer",
      name: "Trainer",
      description: "Academic Faculty/Trainer managing classes, batch schedules, student attendance, and examinations"
    },
    {
      key: "receptionist",
      name: "Receptionist",
      description: "Front Desk Administrator managing student leads, admissions, enrollments, and fee collection"
    },
    {
      key: "student",
      name: "Student",
      description: "Enrolled Student accessing self-service portal, enrolled courses, exams, and certificates"
    }
  ]

  roles_by_key = {}
  system_roles_data.each do |r_data|
    role = Role.find_or_initialize_by(key: r_data[:key], tenant_id: nil)
    role.assign_attributes(name: r_data[:name], description: r_data[:description])
    role.save!
    roles_by_key[r_data[:key]] = role
  end

  # 2. Canonical Permissions (Global definitions)
  permissions_data = [
    # System & Administration
    {
      key: "tenants.manage",
      name: "Manage Tenants",
      module_name: "system",
      description: "Create, view, update, and manage franchise branch tenants"
    },
    {
      key: "users.manage",
      name: "Manage Users",
      module_name: "system",
      description: "Create, update, and manage administrative user accounts"
    },
    {
      key: "roles.manage",
      name: "Manage Roles & Permissions",
      module_name: "system",
      description: "Configure system roles and atomic permission assignments"
    },
    {
      key: "cms.manage",
      name: "Manage CMS Settings",
      module_name: "system",
      description: "Manage global website branding, CMS themes, and promotional banners"
    },

    # Finance & Wallet
    {
      key: "wallet.manage",
      name: "Manage Branch Wallet",
      module_name: "finance",
      description: "View branch wallet ledger, request recharges, and monitor credit/debit transactions"
    },
    {
      key: "fees.collect",
      name: "Collect Student Fees",
      module_name: "finance",
      description: "Process student fee payments, collect installments, and issue official receipts"
    },
    {
      key: "fees.view",
      name: "View Fee Ledger",
      module_name: "finance",
      description: "View student fee histories, payment ledgers, and collection summaries"
    },

    # Academic & Operations
    {
      key: "courses.manage",
      name: "Manage Courses",
      module_name: "academic",
      description: "Create, update, and manage master course definitions and pricing"
    },
    {
      key: "students.manage",
      name: "Manage Students",
      module_name: "academic",
      description: "Register students, update profiles, and manage student KYC documents"
    },
    {
      key: "enrollments.manage",
      name: "Manage Enrollments",
      module_name: "academic",
      description: "Enroll students into courses and manage batch schedules"
    },
    {
      key: "attendance.mark",
      name: "Mark Attendance",
      module_name: "academic",
      description: "Log daily student and class session attendance"
    },

    # Lab & Examinations
    {
      key: "assets.manage",
      name: "Manage Lab Assets",
      module_name: "lab",
      description: "Track hardware assets, computer systems, and submit maintenance tickets"
    },
    {
      key: "exams.manage",
      name: "Manage Online Exams",
      module_name: "lab",
      description: "Create, schedule, and evaluate online student examinations"
    },
    {
      key: "typing.manage",
      name: "Manage Typing Lab",
      module_name: "lab",
      description: "Evaluate Hindi/English typing tests, speed logs, and accuracy metrics"
    },

    # Certification
    {
      key: "certificates.issue",
      name: "Issue Certificates",
      module_name: "certification",
      description: "Authorize and trigger tamper-proof certificate generation for eligible students"
    },
    {
      key: "certificates.revoke",
      name: "Revoke Certificates",
      module_name: "certification",
      description: "Revoke issued certificates and update public verification status"
    }
  ]

  permissions_by_key = {}
  permissions_data.each do |p_data|
    perm = Permission.find_or_initialize_by(key: p_data[:key])
    perm.assign_attributes(
      name: p_data[:name],
      module_name: p_data[:module_name],
      description: p_data[:description]
    )
    perm.save!
    permissions_by_key[p_data[:key]] = perm
  end

  # 3. Role-Permission Matrix Mapping
  role_permissions_matrix = {
    "super_admin" => permissions_data.map { |p| p[:key] },
    "branch_admin" => [
      "users.manage",
      "wallet.manage",
      "fees.collect",
      "fees.view",
      "courses.manage",
      "students.manage",
      "enrollments.manage",
      "attendance.mark",
      "assets.manage",
      "exams.manage",
      "typing.manage",
      "certificates.issue",
      "certificates.revoke"
    ],
    "trainer" => [
      "courses.manage",
      "students.manage",
      "enrollments.manage",
      "attendance.mark",
      "assets.manage",
      "exams.manage",
      "typing.manage"
    ],
    "receptionist" => [
      "students.manage",
      "enrollments.manage",
      "fees.collect",
      "fees.view",
      "attendance.mark"
    ],
    "student" => []
  }

  role_permissions_matrix.each do |role_key, perm_keys|
    role = roles_by_key[role_key]
    next unless role

    perm_keys.each do |perm_key|
      permission = permissions_by_key[perm_key]
      next unless permission

      RolePermission.find_or_create_by!(role: role, permission: permission)
    end
  end
end

unless Rails.env.test?
  puts "[Seeds] Successfully seeded #{Role.where(tenant_id: nil).count} global system roles, #{Permission.count} global permissions, and #{RolePermission.count} role-permission mappings."
end
