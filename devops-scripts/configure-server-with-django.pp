# Install required packages
package { ['git', 'nginx', 'postgresql', 'postgresql-contrib', 'python3-django', 'python3-psycopg2', 'python3-django-rest-framework', 'python3-django-rest-swagger', 'python3-django-rest-framework-simplejwt', 'python3-drf-yasg', 'python3-dotenv']:
  ensure => installed,
}

# Clone Django project from GitHub
$git_repo_url = 'https://github.com/ShymaaIsmail/kid-coder-carnival.git'
$base_directory = '~/'
$project_directory = '~/kid-coder-carnival/kid-coder-carnival-api/kidcodercarnivalapi'

exec { 'clone_or_pull_project':
  command  => "/usr/bin/git -C $base_directory ${'/usr/bin/test -d '}${project_directory} || /usr/bin/git clone $git_repo_url $base_directory",
  logoutput => true,
}

exec { 'git_pull_project':
  command  => "/usr/bin/git -C $project_directory pull",
  unless   => "/usr/bin/test -d $project_directory",
  require  => Exec['clone_or_pull_project'],
}

# Execute setup_postgres_db_prod.sql script as the postgres user
exec { 'setup_postgres_db':
  command => "/usr/bin/psql -U postgres -a -f $project_directory/kidcodercarnivalapi/db/setup_postgres_db_prod.sql",
  unless  => "/usr/bin/psql -U postgres -d kid-code-carnival-prod -c '\q' >/dev/null 2>&1",
}

# Apply Django migrations
exec { 'apply_migrations':
  command => 'python3 manage.py migrate',
  cwd     => $project_directory,
  require => Exec['setup_postgres_db'],
}

# Load initial data
exec { 'load_initial_data':
  command => 'python3 manage.py loaddata admin_user_fixture.json && python3 manage.py loaddata challenges_fixture.json',
  cwd     => $project_directory,
  require => Exec['apply_migrations'],
}

# Run Django server
exec { 'run_django_server':
  command => 'python3 manage.py runserver',
  cwd     => $project_directory,
  require => Exec['load_initial_data'],
}



