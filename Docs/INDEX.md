# 📚 Documentação - Sistema Elemental MCPELEMENTALS

## 🚀 Comece Aqui

1. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** ← **LEIA PRIMEIRO** (5 min)
   - Respostas rápidas às dúvidas mais comuns
   - Qual classe usar aonde
   - Exemplos de código
   - Tabela de referência

2. **[NAMING_CONVENTION.md](NAMING_CONVENTION.md)** (10 min)
   - Entenda POR QUÊ cada classe tem seu nome
   - Convenção completa com regras
   - Checklist de implementação
   - Estrutura de pastas

## 📖 Guias por Tópico

### Implementação
- **[ROCK_SLING_GUIDE.md](ROCK_SLING_GUIDE.md)** - Como funciona Rock Sling (Q)
- **[FIREBALL_GUIDE.md](FIREBALL_GUIDE.md)** - Como funciona FireBall (E)
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Resumo técnico

### Arquitetura
- **[COMPLETE_STRUCTURE.md](COMPLETE_STRUCTURE.md)** - Estrutura detalhada do sistema
- **[SESSION_SUMMARY.md](SESSION_SUMMARY.md)** - Resumo da sessão de desenvolvimento

### Testes
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Como testar no editor Godot

## 🎯 Por Situação

### "Tenho um erro e preciso resolver AGORA"
→ **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** → seção "Erros Comuns e Soluções"

### "Qual classe devo usar?"
→ **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** → tabela "Arquivo → Quando Usar"

### "Quero entender a arquitetura completa"
→ **[COMPLETE_STRUCTURE.md](COMPLETE_STRUCTURE.md)** → seção "Estrutura de Pastas"

### "Vou implementar um novo elemento"
→ **[NAMING_CONVENTION.md](NAMING_CONVENTION.md)** → seção "Regras Simples"

### "Preciso testar Rock Sling e FireBall"
→ **[TESTING_GUIDE.md](TESTING_GUIDE.md)**

### "Quero saber o que foi feito nesta sessão"
→ **[SESSION_SUMMARY.md](SESSION_SUMMARY.md)**

## 📊 Roadmap de Leitura

```
Iniciante:
1. QUICK_REFERENCE.md (5 min)
2. ROCK_SLING_GUIDE.md (10 min)
3. FIREBALL_GUIDE.md (10 min)
4. TESTING_GUIDE.md (10 min)
Total: ~35 minutos

Desenvolvedor:
1. NAMING_CONVENTION.md (10 min)
2. COMPLETE_STRUCTURE.md (15 min)
3. IMPLEMENTATION_SUMMARY.md (10 min)
Total: ~35 minutos

Arquiteto:
1. SESSION_SUMMARY.md (15 min)
2. COMPLETE_STRUCTURE.md (20 min)
3. Todos os guias específicos (30 min)
Total: ~65 minutos
```

## 🔑 Conceitos-Chave

### Nomeação (Sem Conflitos!)
```
ElementsEnum          → Valores de elemento/slot (não é classe)
AbilityResource       → Habilidade que pode ser .tres
ElementKitResource    → Kit de 7 habilidades
ReactionRuleResource  → Regra de reação que pode ser .tres
ElementalCarrierInterface → Interface/contrato
ReactionDatabaseBase  → Classe base para banco de reações
(sem class_name)      → reaction_database_instance.gd (autoload)
ReactionResolver      → Utilidade estática
DamageInfo           → Estrutura de dados
```

### Fluxo de Funcionamento
```
Input (Q, E)
    ↓
Player detects key press
    ↓
start_charge() ou cast()
    ↓
RPC → Server
    ↓
RigidBody3D spawned
    ↓
Physics + Gravidade
    ↓
Colisão detectada
    ↓
ReactionDatabase.find_rule()
    ↓
ReactionResolver.resolve()
    ↓
Outcome executado
```

## ✅ Checklist Rápido

- [ ] Li QUICK_REFERENCE.md
- [ ] Entendi a nomeação em NAMING_CONVENTION.md
- [ ] Testei Rock Sling (Q) e FireBall (E)
- [ ] Todos os arquivos OLD foram deletados
- [ ] project.godot tem autoload sem class_name conflito
- [ ] Sem erro ao abrir o editor

## 📞 Dúvidas?

1. **Erro de nomeação?** → QUICK_REFERENCE.md → tabela "Arquivo → Quando Usar"
2. **Erro ao testar?** → TESTING_GUIDE.md → seção "Debugando Issues"
3. **Quero adicionar novo elemento?** → NAMING_CONVENTION.md → regras
4. **Erro de autoload?** → Verificar se `class_name` conflita com nome do autoload

---

**Última atualização:** 2026-09-13  
**Status:** ✅ Sistema pronto para testes
