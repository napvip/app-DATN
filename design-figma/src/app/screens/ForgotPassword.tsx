import { useState } from 'react';
import { useNavigate, Link } from 'react-router';
import { ArrowLeft, Mail, Check } from 'lucide-react';
import { motion } from 'motion/react';

export function ForgotPassword() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto px-6">
        <div className="flex-1 flex flex-col justify-center py-12">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center space-y-6"
          >
            <div className="bg-[#16A34A]/10 p-6 rounded-full w-fit mx-auto">
              <Check className="w-12 h-12 text-[#16A34A]" />
            </div>
            
            <div>
              <h2 className="text-2xl mb-2">Check Your Email</h2>
              <p className="text-muted-foreground">
                We've sent password reset instructions to<br />
                <span className="text-foreground">{email}</span>
              </p>
            </div>

            <button
              onClick={() => navigate('/login')}
              className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-primary/20"
            >
              Back to Sign In
            </button>
          </motion.div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto px-6">
      <div className="flex-1 flex flex-col justify-center py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="space-y-8"
        >
          {/* Back Button */}
          <button
            onClick={() => navigate('/login')}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>Back to Sign In</span>
          </button>

          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl tracking-tight mb-2">Reset Password</h1>
            <p className="text-muted-foreground">
              Enter your email and we'll send you instructions to reset your password
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email */}
            <div className="space-y-2">
              <label className="text-sm text-muted-foreground">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="alex@example.com"
                  className="w-full pl-12 pr-4 py-4 bg-input-background rounded-2xl border-0 focus:ring-2 focus:ring-primary transition-all outline-none"
                  required
                />
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-primary/20"
            >
              Send Reset Link
            </button>
          </form>
        </motion.div>
      </div>
    </div>
  );
}
