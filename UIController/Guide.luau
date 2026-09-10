local Guide = {}

-- Variáveis do jogador e UI
local player = game.Players.LocalPlayer
local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local GuideFrame = MainGui:WaitForChild("Guide")
local nextButton = GuideFrame:WaitForChild("Next")
local backButton = GuideFrame:WaitForChild("Back")

-- Armazena todas as páginas (de 1 a 10)
local GuidePages = {}
for i = 1, 10 do
	GuidePages[i] = GuideFrame:WaitForChild("Page" .. i)
end

local currentPage = 1 -- Índice baseado em pares (1 = páginas 1 e 2, 2 = páginas 3 e 4, etc.)
local maxPage = math.ceil(#GuidePages / 2) -- Total de pares de páginas

-- Função para alterar páginas
local function changePage(newPage)
	if newPage < 1 or newPage > maxPage then return end -- Evita erros de índice

	-- Esconde todas as páginas primeiro
	for _, page in pairs(GuidePages) do
		page.Visible = false
	end

	-- Calcula os índices das páginas a serem exibidas
	local firstIndex = (newPage - 1) * 2 + 1
	local secondIndex = firstIndex + 1

	-- Torna as duas páginas visíveis
	GuidePages[firstIndex].Visible = true
	if GuidePages[secondIndex] then
		GuidePages[secondIndex].Visible = true
	end

	-- Atualiza o índice da página atual
	currentPage = newPage
end

function Guide.Start()
	-- Esconde todas as páginas e exibe o primeiro par (1 e 2)
	for _, page in pairs(GuidePages) do
		page.Visible = false
	end
	changePage(1) -- Exibe a primeira dupla de páginas

	-- Conectar botões de navegação
	nextButton.MouseButton1Click:Connect(function()
		changePage(currentPage + 1)
	end)

	backButton.MouseButton1Click:Connect(function()
		changePage(currentPage - 1)
	end)
end

return Guide
