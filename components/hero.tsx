"use client"

import { Button } from "@/components/ui/button"
import { ArrowRight } from "lucide-react"

export function Hero() {
  return (
    <section className="relative min-h-[90vh] flex items-center justify-center px-4 py-20 overflow-hidden">
      <div className="absolute inset-0 bg-[linear-gradient(to_right,hsl(var(--border))_1px,transparent_1px),linear-gradient(to_bottom,hsl(var(--border))_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_50%,black_40%,transparent_100%)]" />

      <div className="relative z-10 max-w-4xl mx-auto text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 mb-8 rounded-full border border-border bg-card/50 backdrop-blur-sm">
          <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
          <span className="text-sm font-mono text-muted-foreground">
            v1.0 disponible ahora
          </span>
        </div>

        <h1 className="text-4xl sm:text-5xl md:text-7xl font-bold tracking-tight mb-6">
          <span className="text-foreground">Organiza tu vida</span>
          <br />
          <span className="text-primary text-glow">a tu ritmo</span>
          <span className="inline-block w-[4px] h-[0.9em] bg-primary ml-2 animate-blink align-middle" />
        </h1>

        <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto mb-10 leading-relaxed text-pretty">
          Cue es la herramienta de productividad que se adapta a ti. Simple,
          rapida y sin distracciones. Gestiona tus tareas con la velocidad del
          pensamiento.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Button
            size="lg"
            className="glow-primary bg-primary text-primary-foreground hover:bg-primary/90 px-8 py-6 text-base font-semibold"
          >
            Comenzar gratis
            <ArrowRight className="ml-2 h-5 w-5" />
          </Button>
          <Button
            size="lg"
            variant="outline"
            className="border-border hover:bg-secondary px-8 py-6 text-base"
          >
            <span className="font-mono text-muted-foreground mr-2">$</span>
            Ver demo
          </Button>
        </div>

        <p className="mt-12 text-sm text-muted-foreground">
          <span className="text-primary font-semibold">+2,500</span> personas ya
          organizan su dia con Cue
        </p>
      </div>
    </section>
  )
}
