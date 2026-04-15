import { useState } from 'react';
import { useNavigate } from 'react-router';
import { motion, AnimatePresence } from 'motion/react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';
import { ChevronRight, Hexagon, Camera, TrendingUp } from 'lucide-react';

const slides = [
  {
    icon: Hexagon,
    title: 'Monitor Your Hives Remotely',
    description: 'Keep track of all your beehives from anywhere. Get real-time updates on temperature, humidity, and honey production.',
    image: 'https://images.unsplash.com/photo-1569127971771-15d19a5ba26c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVoaXZlJTIwYmVla2VlcGVyJTIwaG9uZXl8ZW58MXx8fHwxNzc1NzI1Nzc4fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
  },
  {
    icon: Camera,
    title: 'AI Wasp Attack Detection',
    description: 'Advanced AI instantly detects wasp attacks and sends you alerts with captured images, so you can protect your bees immediately.',
    image: 'https://images.unsplash.com/photo-1751167011495-074cf5f9ca66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXNwJTIwaW5zZWN0JTIwY2xvc2V1cHxlbnwxfHx8fDE3NzU3MjU3ODB8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
  },
  {
    icon: TrendingUp,
    title: 'Smart Honey Production Analytics',
    description: 'Track honey production trends, analyze hive performance, and get AI-powered predictions for optimal beekeeping.',
    image: 'https://images.unsplash.com/photo-1758522964459-403b982fb3c2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWVoaXZlJTIwZnJhbWVzJTIwaG9uZXl8ZW58MXx8fHwxNzc1NzI1NzgwfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
  }
];

export function Onboarding() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const navigate = useNavigate();

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      navigate('/login');
    }
  };

  const handleSkip = () => {
    navigate('/login');
  };

  const slide = slides[currentSlide];
  const Icon = slide.icon;

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto">
      {/* Skip Button */}
      <div className="flex justify-end p-6">
        <button
          onClick={handleSkip}
          className="text-muted-foreground hover:text-foreground transition-colors"
        >
          Skip
        </button>
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={currentSlide}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
          transition={{ duration: 0.3 }}
          className="flex-1 flex flex-col px-6 pb-12"
        >
          {/* Image */}
          <div className="flex-1 flex items-center justify-center mb-8">
            <div className="relative w-full aspect-square max-w-sm rounded-[32px] overflow-hidden shadow-2xl">
              <ImageWithFallback
                src={slide.image}
                alt={slide.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent" />
              
              {/* Icon overlay */}
              <div className="absolute top-8 left-8 bg-primary/90 backdrop-blur-sm p-4 rounded-3xl">
                <Icon className="w-8 h-8 text-primary-foreground" strokeWidth={2} />
              </div>
            </div>
          </div>

          {/* Content */}
          <div className="space-y-4">
            <h2 className="text-3xl tracking-tight text-center">
              {slide.title}
            </h2>
            <p className="text-muted-foreground text-center text-lg leading-relaxed">
              {slide.description}
            </p>
          </div>
        </motion.div>
      </AnimatePresence>

      {/* Bottom Navigation */}
      <div className="px-6 pb-8 space-y-6">
        {/* Dots */}
        <div className="flex justify-center gap-2">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all duration-300 ${
                index === currentSlide
                  ? 'w-8 bg-primary'
                  : 'w-2 bg-muted'
              }`}
            />
          ))}
        </div>

        {/* Next Button */}
        <button
          onClick={handleNext}
          className="w-full bg-primary hover:bg-primary/90 text-primary-foreground py-4 rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 shadow-lg shadow-primary/20"
        >
          <span>{currentSlide === slides.length - 1 ? 'Get Started' : 'Continue'}</span>
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
