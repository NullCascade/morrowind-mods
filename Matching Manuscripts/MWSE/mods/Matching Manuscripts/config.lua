return mwse.loadConfig("Matching Manuscripts", {
	enabled = true,
	journalCover = "tx_book_04.tga",
	textureBlacklist = {
		"^tx_book_edge_(.*)%.tga$",
		"^tx_wax_(.*)%.tga$",
	}
})
