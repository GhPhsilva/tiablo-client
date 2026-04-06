# Client: Adicionar Slot de Gloves

## Objetivo

Atualizar a UI do client OtClientV8 para exibir o slot de feet (InventorySlotFeet) abaixo do slot InventorySlotAmmo.

## Contexto

O client usa engine C++ pré-compilada + scripts Lua/OTUI interpretados em runtime. **Não é necessário recompilar o client** — todas as mudanças são em arquivos de dados. Hot-reload disponível com **Ctrl+Shift+R**.

Não é necessário alterar o servidor, essa mudança é apenas visual.


## Dimensões das imagens

- `gloves.png` e `gloves-blessed.png`: **34×34 px** (mesmo padrão dos outros slots)
- Pixel art estilo dos ícones existentes (fundo escuro, contorno, ícone centralizado)
- `gloves-blessed.png`: versão com overlay dourado (mesmo padrão do `*-blessed.png` existente)

## Mudanças necessárias

Vamos alterar o layout, movendo o slot feet (InventorySlotFeet) abaixo do slot ammo (InventorySlotAmmo), para isso vamos precisar mover o slot que mostra a soul para baixo.

## Layout visual resultante

```
         [Head]
[Neck]   [Body]  [Back]
[Left]   [Belt]  [Right]
[Finger] [Legs]  [Ring2]
[Gloves]         [Feet]
                   
```

## Como aplicar sem reiniciar o client

1. Criar as imagens PNG
2. Salvar os arquivos editados
3. Pressionar **Ctrl+Shift+R** dentro do client para hot-reload
