local NPCDialogs = {
	["Leifrik"] = {
		Greetings = {
			"Welcome! Looking for something fresh?",
		},
		Options = {
			[1] = {
				Text = "What do you have to offer?",
				Responses = {
					"Take a look around!",
				},
				Action = "OpenShop",
			},
			[2] = {
				Text = "See you later",
				Responses = {
					"See ya around!",
				},
				Action = "EndDialog",
			},
			[3] = {
				Text = "Bye",
				Responses = {
					"Come back soon!",
				},
				Action = "EndDialog",
			},
		},
	},
	["Haldor"] = {
		Greetings = {
			"What ya need?",
		},
		Options = {
			[1] = {
				Text = "What are you selling?",
				Responses = {
					"What you think? I'm a blacksmith",
				},
				Action = "OpenShop",
			},
			[2] = {
				Text = "I need to craft an Item",
				Responses = {
					"As long as you brought the materials!",
				},
				Action = "OpenCrafting",
			},
			[3] = {
				Text = "Bye",
				Responses = {
					"Bye",
				},
				Action = "EndDialog",
			},
		},
	},
	["Alfrun"] = {
		Greetings = {
			"Hey there! Looking for anything special?",
		},
		Options = {
			[1] = {
				Text = "What are you selling?",
				Responses = {
					"I got exaclty what you're looking for!",
				},
				Action = "OpenShop",
			},
			[2] = {
				Text = "I need to go",
				Responses = {
					"See you around!",
				},
				Action = "EndDialog",
			},
			[3] = {
				Text = "Bye",
				Responses = {
					"Until we meet again!",
				},
				Action = "EndDialog",
			},
		},
	},
	["Eldrim"] = {
		Greetings = {
			"Ah, a fresh face! Sit, sit! I've many tales to tell!",
		},
		Options = {
			[1] = {
				Text = "Tell me a story.",
				Responses = {
					"Ah, excellent! Have you heard of the time Thor lost his hammer?",
					"It was stolen by the giant Thrym, who wanted Freyja in exchange!",
					"So what did Thor do? He disguised himself as a bride!",
					"Picture it: Thor, in a wedding dress, sitting next to Thrym! Ha!",
					"But when Mjölnir was placed in his lap, BOOM! The giant never saw another day.",
					"Now, what shall we talk about next?",
				},
				Action = "ContinueDialog",

				NextOptions = {
					[1] = {
						Text = "Tell me another story!",
						Responses = {
							"Ah, you have good taste! This one is about Loki's trickery.",
							"Once, the gods needed a fortress, and a builder offered to make it.",
							"But he wanted the sun, moon, and Freyja in return!",
							"The gods agreed—until they realized he might finish on time!",
							"So Loki, ever the trickster, turned into a mare and distracted the builder’s stallion.",
							"The fortress wasn't finished, the deal was broken, and Loki? He gave birth to an eight-legged horse named Sleipnir!",
							"A truly bizarre tale, don’t you think?",
						},
						Action = "ContinueDialog",

						NextOptions = {
							[1] = {
								Text = "That was insane! More, please!",
								Responses = {
									"Then let me tell you of Ragnarok, the end of all things...",
									"One day, the sky will burn, and the great wolf Fenrir will break free.",
									"Odin will face his doom, and Thor shall battle the serpent Jörmungandr.",
									"They will slay each other, and the world shall sink into the sea.",
									"But from the ruins, new gods shall rise, and life will begin anew.",
									"Now, tell me, does that story shake your spirit?",
								},
								Action = "ContinueDialog",

								NextOptions = {
									[1] = {
										Text = "I love these epic tales!",
										Responses = {
											"Good! The world is made of stories, and you, my friend, are part of one too.",
										},
										Action = "EndDialog",
									},
									[2] = {
										Text = "I think I've had enough stories for now.",
										Responses = {
											"A shame! But stories are always here, waiting for eager ears.",
										},
										Action = "EndDialog",
									},
									[3] = {
										Text = "I gotta go now.",
										Responses = {
											"Farewell, traveler. May your own tale be worth telling one day!",
										},
										Action = "EndDialog",
									},
								},
							},
							[2] = {
								Text = "Wait, Loki gave birth to a horse?!",
								Responses = {
									"Aye! And not just any horse—Sleipnir, Odin’s mighty steed!",
									"Strange things happen when tricksters meddle in the affairs of gods.",
									"Now, do you wish to hear something even weirder?",
								},
								Action = "ContinueDialog",

								NextOptions = {
									[1] = {
										Text = "Yes! Tell me more.",
										Responses = {
											"Well, Loki had turned into a mare to distract a powerful stallion...",
											"And in doing so, he became the mother of Sleipnir!",
											"The gods were... let's say, surprised.",
										},
										Action = "ResetDialog",
									},
									[2] = {
										Text = "That’s too strange for me...",
										Responses = {
											"Ha! Norse myths are full of strange happenings!",
											"Perhaps another tale, then?",
											"Or do you wish to leave?",
										},
										Action = "ResetDialog",
									},
									[3] = {
										Text = "I think I've heard enough.",
										Responses = { "Very well! May your journeys be filled with adventure!" },
										Action = "EndDialog",
									},
								},
							},
							[3] = {
								Text = "I think I should be going.",
								Responses = {
									"Ah, but there is still so much to tell! No matter, another time then.",
									"May your path be filled with stories worth sharing.",
								},
								Action = "EndDialog",
							},
						},
					},
					[2] = {
						Text = "Who are you, anyway?",
						Responses = {
							"Me? Just a humble storyteller, wandering the realms.",
							"I collect tales like a raven collects shiny things.",
						},
						Action = "EndDialog",
					},
					[3] = {
						Text = "I have no time for stories.",
						Responses = {
							"Ah, a busy traveler! But remember, the greatest warriors still have time to listen.",
							"Perhaps next time, then.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "Who are you?",
				Responses = {
					"Me? Just a humble storyteller, wandering the realms.",
					"I collect tales like a raven collects shiny things.",
					"Speaking of which, would you like to hear one?",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "Yes! Tell me a story.",
						Responses = {
							"Ah, wonderful! Let me tell you of Thor’s mighty hammer…",
						},
						Action = "ContinueDialog",
						NextOptions = {
							[1] = {
								Text = "Of course! Tell me everything.",
								Responses = {
									"Thor’s hammer, Mjölnir, was stolen by the giant Thrym.",
									"In exchange, Thrym demanded Freyja’s hand in marriage!",
									"But the gods had another plan...",
								},
								Action = "ContinueDialog",
								NextOptions = {
									[1] = {
										Text = "What was the plan?",
										Responses = {
											"Thor disguised himself as Freyja and went to the wedding!",
											"The giants were fooled, and when Mjölnir was presented...",
											"Thor grabbed it and struck down Thrym!",
										},
										Action = "EndDialog",
									},
									[2] = {
										Text = "That’s ridiculous!",
										Responses = {
											"Indeed! But such are the ways of the gods.",
											"Sometimes brute force, sometimes cunning...",
										},
										Action = "EndDialog",
									},
									[3] = {
										Text = "I've had enough stories for now.",
										Responses = { "Ah, but there are so many more to tell! Until next time!" },
										Action = "EndDialog",
									},
								},
							},
							[2] = {
								Text = "Actually, I changed my mind.",
								Responses = {
									"No worries, not all stories are for everyone.",
									"Perhaps another time, wanderer.",
									"May your path be filled with adventure.",
								},
								Action = "EndDialog",
							},
							[3] = {
								Text = "I’ll listen another time.",
								Responses = { "Very well! The stories will wait for you." },
								Action = "EndDialog",
							},
						},
					},
					[2] = {
						Text = "Maybe another time.",
						Responses = {
							"A pity! But stories wait for no one. Come back when you wish for one!",
						},
						Action = "EndDialog",
					},
					[3] = {
						Text = "Tell me something funny instead.",
						Responses = {
							"Oh! You’ll like this one! Have you heard how Thor once lost a drinking contest?",
							"He thought he was drinking mead, but it was actually the ocean itself!",
							"Even the gods have their foolish moments!",
						},
						Action = "EndDialog",
					},
				},
			},
			[3] = {
				Text = "Goodbye.",
				Responses = {
					"Ah, leaving so soon? Farewell, then!",
					"May your path be filled with tales worth telling!",
				},
				Action = "EndDialog",
			},
		},
	},
	["Skarde"] = {
		Greetings = {
			"Stand tall, traveler! You look like you have fight in you.",
		},
		Options = {
			[1] = {
				Text = "Who are you?",
				Responses = {
					"I am Skarde, Champion of Bergdalr. Strength is my oath, honor my shield.",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "Can you train me?",
						Responses = {
							"Ha! Training isn't given—it is earned. Prove your spirit first!",
						},
						Action = "EndDialog",
					},
					[2] = {
						Text = "Maybe another time.",
						Responses = {
							"Very well. Come back when your heart burns hotter than steel.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "Can you fight beside me?",
				Responses = {
					"Someday, perhaps. For now, fight your own battles and carve your own saga.",
				},
				Action = "EndDialog",
			},
			[3] = {
				Text = "Goodbye.",
				Responses = {
					"May your axe stay sharp, and your enemies fall before you.",
				},
				Action = "EndDialog",
			},
		},
	},
	["Bjorn"] = {
		Greetings = {
			"You shouldn't trust men like me, traveler.",
		},
		Options = {
			[1] = {
				Text = "What do you mean?",
				Responses = {
					"I am Bjorn, once of Bergdalr... now an outlaw. Justice and I parted ways long ago.",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "What happened?",
						Responses = {
							"Long story. Let's just say... not all wrongdoings are wrong in the eyes of the gods.",
						},
						Action = "EndDialog",
					},
					[2] = {
						Text = "Can you help me?",
						Responses = {
							"Help? I trade favors for coin... or secrets. What do you have to offer?",
						},
						Action = "OpenQuest",
					},
					[3] = {
						Text = "I should go.",
						Responses = {
							"Wise. Too much talk with me and you might find yourself in chains.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "Looking for work?",
				Responses = {
					"Depends. Are you offering something... profitable?",
				},
				Action = "OpenQuest",
			},
			[3] = {
				Text = "Farewell.",
				Responses = {
					"Walk carefully, traveler. The world is hungrier than it seems.",
				},
				Action = "EndDialog",
			},
		},
	},
	["Murk"] = {
		Greetings = {
			"Hehehe... traveler... lost, are we?",
		},
		Options = {
			[1] = {
				Text = "Who are you?",
				Responses = {
					"Murk... that's what they call me. I wander... I watch... I whisper...",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "What are you watching?",
						Responses = {
							"Things unseen. Things better left alone. Hehehe...",
						},
						Action = "EndDialog",
					},
					[2] = {
						Text = "You're creepy.",
						Responses = {
							"Good. Fear keeps you alive longer.",
						},
						Action = "EndDialog",
					},
					[3] = {
						Text = "Goodbye.",
						Responses = {
							"Walk where the shadows don't follow.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "Do you need help?",
				Responses = {
					"Help? Hah! Maybe you should worry about yourself first...",
				},
				Action = "EndDialog",
			},
			[3] = {
				Text = "Goodbye.",
				Responses = {
					"Hehehe... goodbye... for now...",
				},
				Action = "EndDialog",
			},
		},
	},
	["Miner"] = {
		Greetings = {
			"Heya, friend! You lost or just lookin' for somethin' shiny?",
		},
		Options = {
			[1] = {
				Text = "Who are you?",
				Responses = {
					"Name’s Miner! Yep, just Miner. I dig, I sing, and sometimes... I find treasures!",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "Found anything good?",
						Responses = {
							"Couple o' rocks, a bent sword, and once... a shiny gold tooth! Haha!",
						},
						Action = "EndDialog",
					},
					[2] = {
						Text = "Need any help mining?",
						Responses = {
							"Always could use an extra pair o' hands! But mind the cave goblins, they're nasty.",
						},
						Action = "OpenQuest",
					},
					[3] = {
						Text = "Maybe later.",
						Responses = {
							"Suit yourself! The earth's not goin' anywhere.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "Got anything to sell?",
				Responses = {
					"Got some shiny pebbles and rusty junk... might be worth somethin' to the right fella!",
				},
				Action = "OpenShop",
			},
			[3] = {
				Text = "Goodbye.",
				Responses = {
					"Safe travels, friend! Mind your step, lots of loose rocks around here!",
				},
				Action = "EndDialog",
			},
		},
	},
	["Volva"] = { -- The witch that gives the player its path Aegishjalmur = Paladin & Warrior, Vegvisir = Warden & Mage.
		Greetings = {
			"Oh it seems I have been noticed, tell me, what do you seek?",
		},
		Options = {
			[1] = {
				Text = "Who are you?",
				Responses = {
					"I am Volva, a seer of the old ways. I can guide you if you are lost.",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "I seek guidance.",
						Responses = {
							"Very well. Vegvisir seems to fit you.",
						},
						Action = "ChoosePathVegvisir",
					},
					[2] = {
						Text = "I seek Power.",
						Responses = {
							"Very well. Aegishjalmur seems to fit you.",
						},
						Action = "ChoosePathAegishjalmur",
					},
					[3] = {
						Text = "I have no time for this.",
						Responses = {
							"Then go, but remember, your path is a one way street.",
						},
						Action = "EndDialog",
					},
				},
			},
			[2] = {
				Text = "I'm lost.",
				Responses = {
					"The world is vast, but I can help you find your way.",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "I seek guidance.",
						Responses = {
							"Very well. Vegvisir seems to fit you.",
						},
						Action = "ChoosePathVegvisir",
					},
					[2] = {
						Text = "I seek Power.",
						Responses = {
							"Very well. Aegishjalmur seems to fit you.",
						},
						Action = "ChoosePathAegishjalmur",
					},
					[3] = {
						Text = "I have no time for this.",
						Responses = {
							"Then go, but remember, your path is a one way street.",
						},
						Action = "EndDialog",
					},
				},
			},
			[3] = {
				Text = "Goodbye.",
				Responses = {
					"Farewell, traveler. Try not to stray too far from your path.",
				},
				Action = "EndDialog",
			},
		},
	},
	["Volva2"] = {
		Greetings = {
			"Your destiny is already set. You cannot change your path.",
		},
		Options = {
			[1] = {
				Text = "I understand.",
				Responses = {
					"Choose wisely, to avoid regret.",
				},
				Action = "EndDialog",
			},
			[2] = {
				Text = "I don't want to follow this path anymore.",
				Responses = {
					"Regret is a heavy burden to bear. If you truly wish to change your path, you must be prepared to give up everything you have achieved.",
				},
				Action = "ContinueDialog",
				NextOptions = {
					[1] = {
						Text = "I am ready to give up everything.",
						Responses = {
							"Are you sure you want to change your path? This will reset your progress and you will lose all your current level and abilities.",
						},
						Action = "ContinueDialog",
						NextOptions = {
							[1] = {
								Text = "Yes, I want to change my path.",
								Responses = {
									"Very well. You will be reborn into a new being, free from your past choices.",
								},
								Action = "ResetPath",
							},
							[2] = {
								Text = "I need more time to think.",
								Responses = {
									"Take your time, but remember, the longer you wait, the more you lose.",
								},
								Action = "EndDialog",
							},
							[3] = {
								Text = "Never mind.",
								Responses = {
									"Very well. But remember, your path is a one way street.",
								},
								Action = "EndDialog",
							},
						},
					},
					[2] = {
						Text = "I need more time to think.",
						Responses = {
							"Take your time, but remember, the longer you wait, the more you lose.",
						},
						Action = "EndDialog",
					},
					[3] = {
						Text = "Never mind.",
						Responses = {
							"Very well. But remember, your path is a one way street.",
						},
						Action = "EndDialog",
					},
				},
			},
			[3] = {
				Text = "Never mind.",
				Responses = {
					"Very well. But remember, your path is a one way street.",
				},
				Action = "EndDialog",
			},
		},
	},
	["Bonfire"] = { --Not an NPC, but a dialog for the bonfire cooking station
		Greetings = {
			"The fire crackles, and the smell of smoke fills the air. You can cook here or rest for a while.",
		},
		Options = {
			[1] = {
				Text = "Cook",
				Action = "OpenBonfire",
			},
			[2] = {
				Text = "Rest",
				Action = "RestAtBonfire",
			},
			[3] = {
				Text = "Leave",
				Action = "EndDialog",
			},
		},
	},
}

return NPCDialogs
