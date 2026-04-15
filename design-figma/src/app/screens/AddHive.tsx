import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, QrCode, Camera, Loader2, Check } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

type Step = 'scan' | 'connecting' | 'success';

export function AddHive() {
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>('scan');

  const handleScan = () => {
    setStep('connecting');
    setTimeout(() => {
      setStep('success');
    }, 2000);
  };

  const handleDone = () => {
    navigate('/app');
  };

  return (
    <div className="min-h-screen bg-background max-w-md mx-auto flex flex-col">
      {/* Header */}
      <div className="sticky top-0 bg-background/80 backdrop-blur-xl border-b border-border z-10">
        <div className="flex items-center gap-4 px-6 py-4">
          <button
            onClick={() => navigate('/app')}
            className="text-foreground hover:text-primary transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h2>Add New Hive</h2>
            <p className="text-sm text-muted-foreground">Scan QR code on device</p>
          </div>
        </div>
      </div>

      <div className="flex-1 flex items-center justify-center px-6 py-12">
        <AnimatePresence mode="wait">
          {/* Scan Step */}
          {step === 'scan' && (
            <motion.div
              key="scan"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="w-full max-w-sm text-center"
            >
              <div className="relative mb-8">
                {/* QR Scanner Frame */}
                <div className="w-full aspect-square bg-muted rounded-3xl relative overflow-hidden">
                  {/* Animated scanning line */}
                  <motion.div
                    className="absolute left-0 right-0 h-1 bg-primary shadow-lg shadow-primary/50"
                    animate={{ top: ['0%', '100%'] }}
                    transition={{ 
                      duration: 2, 
                      repeat: Infinity, 
                      ease: 'linear' 
                    }}
                  />
                  
                  {/* Corner markers */}
                  <div className="absolute top-8 left-8 w-12 h-12 border-t-4 border-l-4 border-primary rounded-tl-2xl" />
                  <div className="absolute top-8 right-8 w-12 h-12 border-t-4 border-r-4 border-primary rounded-tr-2xl" />
                  <div className="absolute bottom-8 left-8 w-12 h-12 border-b-4 border-l-4 border-primary rounded-bl-2xl" />
                  <div className="absolute bottom-8 right-8 w-12 h-12 border-b-4 border-r-4 border-primary rounded-br-2xl" />

                  {/* Camera icon */}
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Camera className="w-16 h-16 text-muted-foreground" />
                  </div>
                </div>
              </div>

              <h3 className="mb-3">Position QR Code</h3>
              <p className="text-muted-foreground mb-8">
                Align the QR code on your BeeGuard device within the frame
              </p>

              <button
                onClick={handleScan}
                className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-primary/20"
              >
                Simulate Scan
              </button>
            </motion.div>
          )}

          {/* Connecting Step */}
          {step === 'connecting' && (
            <motion.div
              key="connecting"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="w-full max-w-sm text-center"
            >
              <div className="bg-primary/10 p-8 rounded-full w-fit mx-auto mb-8">
                <Loader2 className="w-16 h-16 text-primary animate-spin" />
              </div>
              <h3 className="mb-3">Connecting to Device</h3>
              <p className="text-muted-foreground">
                Please wait while we establish a secure connection...
              </p>
            </motion.div>
          )}

          {/* Success Step */}
          {step === 'success' && (
            <motion.div
              key="success"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="w-full max-w-sm text-center"
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
                className="bg-[#16A34A]/10 p-8 rounded-full w-fit mx-auto mb-8"
              >
                <Check className="w-16 h-16 text-[#16A34A]" />
              </motion.div>
              
              <h3 className="mb-3">Device Connected!</h3>
              <p className="text-muted-foreground mb-8">
                Your new hive has been successfully added and is now being monitored.
              </p>

              <div className="bg-card rounded-3xl p-6 border border-border mb-8 text-left">
                <h4 className="mb-4">Device Information</h4>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Device ID</span>
                    <span>BG-4521-8932</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Hive Name</span>
                    <span>Hive Epsilon</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Battery</span>
                    <span className="text-[#16A34A]">98%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Status</span>
                    <span className="text-[#16A34A]">Online</span>
                  </div>
                </div>
              </div>

              <button
                onClick={handleDone}
                className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl transition-all active:scale-95 shadow-lg shadow-primary/20"
              >
                Go to Dashboard
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
