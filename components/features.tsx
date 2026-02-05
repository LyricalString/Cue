import { Zap, Keyboard, Shield, Clock } from "lucide-react";

const features = [
  {
    icon: Zap,
    title: "Rapida como el rayo",
    description:
      "Interfaz optimizada para que captures tus ideas al instante. Sin cargas, sin esperas.",
    command: "cue add",
  },
  {
    icon: Keyboard,
    title: "Atajos intuitivos",
    description:
      "Navega y gestiona todo con el teclado. Aprende una vez, usa para siempre.",
    command: "Ctrl + N",
  },
  {
    icon: Shield,
    title: "Privacidad primero",
    description:
      "Tus datos son tuyos. Sin rastreo, sin anuncios, sin compromisos.",
    command: "--private",
  },
  {
    icon: Clock,
    title: "Sincroniza todo",
    description:
      "Accede a tus tareas desde cualquier dispositivo. Siempre actualizado.",
    command: "cue sync",
  },
];

export function Features() {
  return (
    <section className="py-24 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Section header */}
        <div className="text-center mb-16">
          <p className="text-sm font-mono text-primary mb-4 tracking-wider uppercase">
            // Caracteristicas
          </p>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold text-foreground text-balance">
            Todo lo que necesitas,
            <br />
            nada que no
          </h2>
        </div>

        {/* Features grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {features.map((feature, index) => (
            <div
              key={index}
              className="group relative p-8 rounded-lg border border-border bg-card/50 hover:bg-card hover:border-primary/50 transition-all duration-300"
            >
              {/* Icon */}
              <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-6 group-hover:bg-primary/20 transition-colors">
                <feature.icon className="w-6 h-6 text-primary" />
              </div>

              {/* Content */}
              <h3 className="text-xl font-semibold text-foreground mb-3">
                {feature.title}
              </h3>
              <p className="text-muted-foreground leading-relaxed mb-4">
                {feature.description}
              </p>

              {/* Command hint */}
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded bg-secondary font-mono text-sm text-muted-foreground">
                <span className="text-primary">{">"}</span>
                {feature.command}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
