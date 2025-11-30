import os
import sys

base = r'c:\Users\luann\Documents\GitHub\mathquest\lib'

dirs = [
    'core/constants',
    'core/errors', 
    'core/network',
    'core/utils',
    'core/extensions',
    'data/models',
    'data/repositories',
    'data/datasources/local',
    'data/datasources/remote',
    'domain/entities',
    'domain/usecases/auth',
    'domain/usecases/lessons',
    'domain/usecases/progress',
    'presentation/screens/splash/widgets',
    'presentation/screens/onboarding/widgets',
    'presentation/screens/auth/widgets',
    'presentation/screens/home/widgets',
    'presentation/screens/lesson_map/widgets',
    'presentation/screens/gameplay/widgets',
    'presentation/screens/results/widgets',
    'presentation/screens/profile/widgets',
    'presentation/screens/leaderboard/widgets',
    'presentation/screens/shop/widgets',
    'presentation/screens/settings/widgets',
    'presentation/widgets/common',
    'presentation/widgets/animations',
    'presentation/widgets/badges',
    'presentation/providers',
    'l10n'
]

for d in dirs:
    full_path = os.path.join(base, d.replace('/', os.sep))
    try:
        os.makedirs(full_path, exist_ok=True)
        print(f'Created: {full_path}')
    except Exception as e:
        print(f'Error creating {full_path}: {e}')

print('Done!')
