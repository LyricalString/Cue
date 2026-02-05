"use client"

import { ArrowRight } from "lucide-react"

export function CTA() {
  return (
    <section className="py-24 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="relative rounded-2xl border border-border bg-card/50 p-8 sm:p-12 md:p-16 overflow-hidden">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-96 h-96 bg-primary/20 rounded-full blur-3xl -translate-y-1/2" />

          <div className="relative z-10 text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 mb-8 rounded bg-secondary font-mono text-sm">
              <span className="text-primary">{"$"}</span>
              <span className="text-muted-foreground">cue init --mi-vida</span>
              <span className="w-2 h-4 bg-primary animate-blink" />
            </div>

            <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold text-foreground mb-6 text-balance">
              Empieza a organizarte hoy
            </h2>

            <p className="text-lg text-muted-foreground max-w-xl mx-auto mb-10 leading-relaxed">
              Sin tarjeta de credito. Sin compromisos. Solo tu y tus tareas, en
              perfecta armonia.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <button className="glow-primary inline-flex items-center justify-center bg-primary text-primary-foreground hover:bg-primary/90 px-8 py-4 text-base font-semibold rounded-md transition-colors">
                Crear cuenta gratis
                <ArrowRight className="ml-2 h-5 w-5" />
              </button>
            </div>

            <p className="mt-8 text-sm text-muted-foreground">
              Configura tu espacio en menos de{" "}
              <span className="text-primary font-mono">60 segundos</span>
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
