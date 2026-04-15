import { TrendingUp, Award, Lightbulb, BarChart3 } from 'lucide-react';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const monthlyProduction = [
  { hive: 'Alpha', production: 45 },
  { hive: 'Beta', production: 32 },
  { hive: 'Gamma', production: 51 },
  { hive: 'Delta', production: 38 },
];

const monthComparison = [
  { month: 'Jan', production: 120 },
  { month: 'Feb', production: 145 },
  { month: 'Mar', production: 168 },
  { month: 'Apr', production: 166 },
];

const performanceData = [
  { name: 'Excellent', value: 2, color: '#16A34A' },
  { name: 'Good', value: 1, color: '#F5B400' },
  { name: 'Needs Attention', value: 1, color: '#F97316' },
];

const recommendations = [
  {
    id: 1,
    title: 'Optimal Harvesting Time',
    description: 'Hive Gamma is ready for honey extraction. Estimated yield: 18-22kg',
    priority: 'high',
    action: 'Schedule harvest',
  },
  {
    id: 2,
    title: 'Temperature Management',
    description: 'Hive Beta experiencing higher temperatures. Consider additional ventilation.',
    priority: 'medium',
    action: 'Review settings',
  },
  {
    id: 3,
    title: 'Maintenance Due',
    description: 'Hive Delta device battery needs replacement within 5 days.',
    priority: 'low',
    action: 'Schedule service',
  },
];

export function Insights() {
  const totalProduction = monthlyProduction.reduce((sum, hive) => sum + hive.production, 0);
  const avgPerHive = (totalProduction / monthlyProduction.length).toFixed(1);
  const bestPerformer = monthlyProduction.reduce((best, hive) => 
    hive.production > best.production ? hive : best
  );

  return (
    <div className="min-h-screen bg-background max-w-md mx-auto">
      {/* Header */}
      <div className="px-6 pt-12 pb-6">
        <h1 className="text-3xl tracking-tight mb-2">Insights</h1>
        <p className="text-muted-foreground">Advanced analytics & recommendations</p>
      </div>

      <div className="px-6 space-y-6 pb-6">
        {/* Key Metrics */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-gradient-to-br from-primary/10 via-primary/5 to-transparent rounded-3xl p-5 border border-primary/20">
            <div className="bg-primary/20 p-2 rounded-xl w-fit mb-3">
              <TrendingUp className="w-5 h-5 text-primary" />
            </div>
            <div className="text-3xl mb-1">{totalProduction}kg</div>
            <p className="text-sm text-muted-foreground">Total this month</p>
            <div className="text-xs text-[#16A34A] mt-2">+12% vs last month</div>
          </div>

          <div className="bg-gradient-to-br from-[#16A34A]/10 via-[#16A34A]/5 to-transparent rounded-3xl p-5 border border-[#16A34A]/20">
            <div className="bg-[#16A34A]/20 p-2 rounded-xl w-fit mb-3">
              <BarChart3 className="w-5 h-5 text-[#16A34A]" />
            </div>
            <div className="text-3xl mb-1">{avgPerHive}kg</div>
            <p className="text-sm text-muted-foreground">Avg per hive</p>
            <div className="text-xs text-[#16A34A] mt-2">Above target</div>
          </div>
        </div>

        {/* Best Performer */}
        <div className="bg-gradient-to-br from-primary via-primary to-[#E5A300] rounded-3xl p-6 text-white">
          <div className="flex items-start justify-between mb-4">
            <div className="bg-white/20 backdrop-blur-sm p-3 rounded-2xl">
              <Award className="w-6 h-6" />
            </div>
            <span className="text-sm opacity-90">This Month</span>
          </div>
          <h3 className="mb-2">Best Performing Hive</h3>
          <div className="flex items-baseline gap-2 mb-1">
            <span className="text-3xl">Hive {bestPerformer.hive}</span>
          </div>
          <p className="text-sm opacity-90">
            Produced {bestPerformer.production}kg of honey - 23% above average
          </p>
        </div>

        {/* Production by Hive */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <h4 className="mb-4">Production by Hive (April)</h4>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={monthlyProduction}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E5E5" />
              <XAxis dataKey="hive" tick={{ fontSize: 12 }} stroke="#737373" />
              <YAxis tick={{ fontSize: 12 }} stroke="#737373" />
              <Tooltip />
              <Bar dataKey="production" fill="#F5B400" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Monthly Comparison */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <h4 className="mb-4">Monthly Production Trend</h4>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={monthComparison}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E5E5" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} stroke="#737373" />
              <YAxis tick={{ fontSize: 12 }} stroke="#737373" />
              <Tooltip />
              <Line 
                type="monotone" 
                dataKey="production" 
                stroke="#16A34A" 
                strokeWidth={3} 
                dot={{ fill: '#16A34A', r: 5 }} 
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Hive Health Distribution */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <h4 className="mb-4">Hive Health Overview</h4>
          <div className="flex items-center gap-6">
            <ResponsiveContainer width="50%" height={160}>
              <PieChart>
                <Pie
                  data={performanceData}
                  cx="50%"
                  cy="50%"
                  innerRadius={40}
                  outerRadius={70}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {performanceData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="flex-1 space-y-2">
              {performanceData.map((item) => (
                <div key={item.name} className="flex items-center gap-2">
                  <div 
                    className="w-3 h-3 rounded-full" 
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="text-sm">{item.name}</span>
                  <span className="text-sm text-muted-foreground ml-auto">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* AI Recommendations */}
        <div className="bg-card rounded-3xl p-6 border border-border">
          <div className="flex items-center gap-3 mb-4">
            <Lightbulb className="w-5 h-5 text-primary" />
            <h4>AI Recommendations</h4>
          </div>
          <div className="space-y-4">
            {recommendations.map((rec) => (
              <div 
                key={rec.id}
                className="bg-muted/50 rounded-2xl p-4 space-y-3"
              >
                <div className="flex items-start justify-between gap-2">
                  <h5 className="text-sm">{rec.title}</h5>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    rec.priority === 'high' 
                      ? 'bg-[#DC2626] text-white'
                      : rec.priority === 'medium'
                      ? 'bg-[#F97316] text-white'
                      : 'bg-primary text-primary-foreground'
                  }`}>
                    {rec.priority.charAt(0).toUpperCase() + rec.priority.slice(1)}
                  </span>
                </div>
                <p className="text-sm text-muted-foreground">
                  {rec.description}
                </p>
                <button className="text-sm text-primary hover:underline">
                  {rec.action} →
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
