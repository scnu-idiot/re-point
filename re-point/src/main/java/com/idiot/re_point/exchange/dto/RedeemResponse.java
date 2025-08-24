package com.idiot.re_point.exchange.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class RedeemResponse {
    private String exchangeId;   // exchanges 컬렉션에 생성된 문서 id
    private String code;         // 발급된 상품권 코드
    private long   pointsUsed;   // 차감 포인트
    private long   balanceAfter; // 차감 후 사용자 보유 포인트
}