import { useRouteError, useNavigate } from 'react-router';
import { AlertTriangle, Home } from 'lucide-react';

export function ErrorBoundary() {
  const error = useRouteError() as any;
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-6 max-w-md mx-auto">
      <div className="text-center space-y-6">
        <div className="bg-red-500/10 p-6 rounded-full w-fit mx-auto">
          <AlertTriangle className="w-12 h-12 text-red-500" />
        </div>
        
        <div>
          <h2 className="text-2xl mb-2">Oops! Something went wrong</h2>
          <p className="text-muted-foreground">
            {error?.statusText || error?.message || 'An unexpected error occurred'}
          </p>
        </div>

        <div className="space-y-3">
          <button
            onClick={() => navigate('/app')}
            className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-primary/20 flex items-center justify-center gap-2"
          >
            <Home className="w-5 h-5" />
            Go to Home
          </button>
          
          <button
            onClick={() => window.location.reload()}
            className="w-full bg-input-background hover:bg-input-background/80 text-foreground py-4 rounded-2xl transition-all active:scale-95"
          >
            Reload Page
          </button>
        </div>
      </div>
    </div>
  );
}
