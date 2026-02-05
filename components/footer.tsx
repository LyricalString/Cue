export function Footer() {
  return (
    <footer className="border-t border-border py-12 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-primary flex items-center justify-center">
              <span className="font-mono font-bold text-primary-foreground text-xs">
                {"C_"}
              </span>
            </div>
            <span className="font-semibold text-foreground">Cue</span>
          </div>

          <nav className="flex items-center gap-6 text-sm">
            <a
              href="#"
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              Privacidad
            </a>
            <a
              href="#"
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              Terminos
            </a>
            <a
              href="#"
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              Contacto
            </a>
          </nav>

          <p className="text-sm text-muted-foreground font-mono">
            <span className="text-primary">{">"}</span> 2026 Cue. Todos los
            derechos reservados.
          </p>
        </div>
      </div>
    </footer>
  )
}
