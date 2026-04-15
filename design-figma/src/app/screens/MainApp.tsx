import { Outlet, useNavigate, useLocation } from 'react-router';
import { Home, Bell, TrendingUp, Wrench, User } from 'lucide-react';

const tabs = [
  { path: '/app', icon: Home, label: 'Home' },
  { path: '/app/alerts', icon: Bell, label: 'Alerts' },
  { path: '/app/insights', icon: TrendingUp, label: 'Insights' },
  { path: '/app/maintenance', icon: Wrench, label: 'Maintenance' },
  { path: '/app/profile', icon: User, label: 'Profile' },
];

export function MainApp() {
  const navigate = useNavigate();
  const location = useLocation();

  const isActive = (path: string) => {
    if (path === '/app') {
      return location.pathname === '/app';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto relative pb-20">
      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <Outlet />
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-card border-t border-border max-w-md mx-auto">
        <div className="grid grid-cols-5 h-20">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const active = isActive(tab.path);
            
            return (
              <button
                key={tab.path}
                onClick={() => navigate(tab.path)}
                className="flex flex-col items-center justify-center gap-1 transition-colors"
              >
                <div className={`transition-all ${active ? 'text-primary' : 'text-muted-foreground'}`}>
                  <Icon className="w-6 h-6" strokeWidth={active ? 2.5 : 2} />
                </div>
                <span className={`text-xs ${active ? 'text-primary' : 'text-muted-foreground'}`}>
                  {tab.label}
                </span>
                {active && (
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-12 h-1 bg-primary rounded-b-full" />
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
