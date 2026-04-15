import { ChevronRight, User, Bell, Moon, Globe, Download, LogOut, Hexagon } from 'lucide-react';
import { Switch } from '../components/ui/switch';

const menuItems = [
  {
    section: 'Account',
    items: [
      { icon: User, label: 'Personal Information', action: 'navigate' },
      { icon: Bell, label: 'Notification Settings', action: 'navigate' },
    ],
  },
  {
    section: 'Preferences',
    items: [
      { icon: Moon, label: 'Dark Mode', action: 'toggle', value: false },
      { icon: Globe, label: 'Language', action: 'navigate', value: 'English' },
    ],
  },
  {
    section: 'Data',
    items: [
      { icon: Download, label: 'Export Data (PDF/CSV)', action: 'navigate' },
    ],
  },
];

export function Profile() {
  return (
    <div className="min-h-screen bg-background max-w-md mx-auto">
      {/* Header */}
      <div className="px-6 pt-12 pb-8">
        <h1 className="text-3xl tracking-tight mb-2">Profile</h1>
        <p className="text-muted-foreground">Manage your account & preferences</p>
      </div>

      {/* User Card */}
      <div className="px-6 mb-8">
        <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-transparent rounded-3xl p-6 border border-primary/20">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center">
              <User className="w-8 h-8 text-primary" />
            </div>
            <div>
              <h3>Alex Johnson</h3>
              <p className="text-sm text-muted-foreground">alex@example.com</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-primary/10">
            <div>
              <div className="text-2xl mb-1">4</div>
              <p className="text-xs text-muted-foreground">Active Hives</p>
            </div>
            <div>
              <div className="text-2xl mb-1">166kg</div>
              <p className="text-xs text-muted-foreground">Total Honey</p>
            </div>
            <div>
              <div className="text-2xl mb-1">89%</div>
              <p className="text-xs text-muted-foreground">Health Score</p>
            </div>
          </div>
        </div>
      </div>

      {/* Menu Sections */}
      <div className="px-6 space-y-6 pb-6">
        {menuItems.map((section) => (
          <div key={section.section}>
            <h4 className="text-sm text-muted-foreground mb-3 px-2">{section.section}</h4>
            <div className="bg-card rounded-3xl border border-border overflow-hidden">
              {section.items.map((item, index) => {
                const Icon = item.icon;
                const isLast = index === section.items.length - 1;
                
                return (
                  <div key={item.label}>
                    <button className="w-full flex items-center justify-between p-4 hover:bg-muted transition-colors">
                      <div className="flex items-center gap-3">
                        <Icon className="w-5 h-5 text-muted-foreground" />
                        <span>{item.label}</span>
                      </div>
                      {item.action === 'toggle' ? (
                        <Switch defaultChecked={item.value as boolean} />
                      ) : (
                        <div className="flex items-center gap-2 text-muted-foreground">
                          {item.value && <span className="text-sm">{item.value}</span>}
                          <ChevronRight className="w-5 h-5" />
                        </div>
                      )}
                    </button>
                    {!isLast && <div className="h-px bg-border mx-4" />}
                  </div>
                );
              })}
            </div>
          </div>
        ))}

        {/* Logout Button */}
        <button className="w-full bg-card hover:bg-muted border border-border text-[#DC2626] rounded-3xl p-4 flex items-center justify-center gap-3 transition-all active:scale-95">
          <LogOut className="w-5 h-5" />
          <span>Sign Out</span>
        </button>

        {/* App Info */}
        <div className="pt-8 pb-4 text-center space-y-4">
          <div className="flex justify-center">
            <div className="bg-primary/10 p-3 rounded-2xl">
              <Hexagon className="w-8 h-8 text-primary" strokeWidth={1.5} />
            </div>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">BeeGuard v1.0.0</p>
            <p className="text-xs text-muted-foreground mt-1">© 2026 BeeGuard Inc.</p>
          </div>
          <div className="flex justify-center gap-4 text-sm">
            <button className="text-primary hover:underline">Privacy Policy</button>
            <span className="text-muted-foreground">•</span>
            <button className="text-primary hover:underline">Terms of Service</button>
          </div>
        </div>
      </div>
    </div>
  );
}
