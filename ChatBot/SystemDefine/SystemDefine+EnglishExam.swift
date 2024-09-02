//
//  SystemDefine+EnglishExam.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/28.
//

import Foundation


typealias TOEICGrammarPoint = SystemDefine.EnglishExam.TOEICGrammarPoint

extension SystemDefine {
    
    
    //MARK: - 英文測驗
    struct EnglishExam {
        
        //MARK: - 問題類型
        enum QuestionType: CaseIterable {
            
            /// 單純的單字測驗
            case vocabularyWord(letter: String, sortOption: SystemDefine.EnglishExam.SortOption)
            /// 單字克漏字填空
            case vocabularyCloze(letter: String, sortOption: SystemDefine.EnglishExam.SortOption)
            /// 文法題
            case grammar(point: TOEICGrammarPoint?)
            
            static var allCases: [QuestionType] {
                return [
                    .vocabularyWord(letter: "", sortOption: .familiarity),
                    .vocabularyCloze(letter: "", sortOption: .familiarity)
                ]
            }
            
            var title: String {
                switch self {
                case .vocabularyWord:
                    return "字義選擇"
                case .vocabularyCloze:
                    return "克漏字選擇"
                case .grammar:
                    return "文法測驗"
                }
            }
        }
        
        //MARK: - 排序方式
        enum SortOption: String, CaseIterable {
            case familiarity = "依照熟悉度"
            case lastWatchTime = "依照觀看日期"
            case star = "星號"
        }
        
        //MARK: - 多益考試常見的英文語法類型
        enum TOEICGrammarPoint: String, CaseIterable, Codable {
    
            case Tense = "時態"
            case VerbForm = "動詞形式和語態"
            case Pronoun = "代詞"
            case AdjectiveAdverb = "形容詞和副詞"
            case Preposition = "介詞"
            case Conjunction = "連詞"
            case Article = "冠詞"
            case ConditionalSentence = "條件句"
            case reportedSpeech = "間接引語"
            case subjectVerbAgreement = "主謂一致"
            case quantifier = "限定詞"
            case relativeClause = "定語從句"
            case parallelism = "平行結構"
            case inversion = "倒裝結構"
            
            static func randomGrammarPoint() -> TOEICGrammarPoint {
                return allCases.randomElement() ?? .Tense
            }
            
            func randomSubType() -> String {
                switch self {
                case .Tense:
                    return TenseType.allCases.randomElement()?.rawValue ?? "現在簡單式"
                case .VerbForm:
                    return VerbFormType.allCases.randomElement()?.rawValue ?? "主動語態"
                case .Pronoun:
                    return PronounType.allCases.randomElement()?.rawValue ?? "主格代詞"
                case .AdjectiveAdverb:
                    return AdjectiveAdverbType.allCases.randomElement()?.rawValue ?? "形容詞/副詞的比較級"
                case .Preposition:
                    return PrepositionType.allCases.randomElement()?.rawValue ?? "時間介詞"
                case .Conjunction:
                    return ConjunctionType.allCases.randomElement()?.rawValue ?? "並列連詞"
                case .Article:
                    return ArticleType.allCases.randomElement()?.rawValue ?? "不定冠詞"
                case .ConditionalSentence:
                    return ConditionalSentenceType.allCases.randomElement()?.rawValue ?? "零條件句"
                case .reportedSpeech:
                    return "間接引語"
                case .subjectVerbAgreement:
                    return "主謂一致"
                case .quantifier:
                    return "限定詞"
                case .relativeClause:
                    return "定語從句"
                case .parallelism:
                    return "平行結構"
                case .inversion:
                    return "倒裝結構"
                }
            }
            
            /// 時態的子類型
            enum TenseType: String, CaseIterable  {
                /// 現在時態
                case presentSimple = "現在簡單式"
                case presentContinuous = "現在進行式"
                case presentPerfect = "現在完成式"
                case presentPerfectContinuous = "現在完成進行式"
                
                /// 過去時態
                case pastSimple = "過去簡單式"
                case pastContinuous = "過去進行式"
                case pastPerfect = "過去完成式"
                case pastPerfectContinuous = "過去完成進行式"
                
                /// 將來時態
                case futureSimple = "將來簡單式"
                case futureContinuous = "將來進行式"
                case futurePerfect = "將來完成式"
                case futurePerfectContinuous = "將來完成進行式"
            }
            
            /// 動詞形式和語態的子類型
            enum VerbFormType: String, CaseIterable {
                case activeVoice = "主動語態"
                case passiveVoice = "被動語態"
                case infinitive = "不定詞"
                case gerund = "動名詞"
                case participle = "分詞"
            }
            
            /// 代詞的子類型
            enum PronounType: String, CaseIterable {
                case subjective = "主格代詞"
                case objective = "賓格代詞"
                case reflexive = "反身代詞"
                case demonstrative = "指示代詞"
                case relative = "關係代詞"
            }
            
            /// 形容詞和副詞的子類型
            enum AdjectiveAdverbType: String, CaseIterable {
                case comparative = "形容詞/副詞的比較級"
                case superlative = "形容詞/副詞的最高級"
                case adjectivePlacement = "形容詞位置"
                case adverbPlacement = "副詞位置"
                case intensifier = "程度副詞"
            }
            
            /// 介詞的子類型
            enum PrepositionType: String, CaseIterable {
                case time = "時間介詞"
                case place = "地點介詞"
                case direction = "方向介詞"
            }
            
            /// 連詞的子類型
            enum ConjunctionType: String, CaseIterable {
                case coordinating = "並列連詞"
                case subordinating = "從屬連詞"
                case correlative = "相關連詞"
            }
            
            /// 冠詞的子類型
            enum ArticleType: String, CaseIterable {
                case indefinite = "不定冠詞"
                case definite = "定冠詞"
                case zeroArticle = "零冠詞"
            }
            
            /// 條件句的子類型
            enum ConditionalSentenceType: String, CaseIterable {
                case zeroConditional = "零條件句"
                case firstConditional = "第一條件句"
                case secondConditional = "第二條件句"
                case thirdConditional = "第三條件句"
            }
        }
        
    }
}
