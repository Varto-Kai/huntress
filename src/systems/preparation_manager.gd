class_name PreparationManager
extends PreparationData
## Subclasse de compatibilidade retroativa que estende PreparationData (Resource serializável).
## Preserva 100% de compatibilidade para chamadores e suítes de teste que instanciam PreparationManager.new() (SPEC-004 / Issue #26).
