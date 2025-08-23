package com.idiot.re_point.point.dto;

import lombok.*;
import java.time.Instant;

@Getter @Setter
@Builder
@AllArgsConstructor @NoArgsConstructor
public class PointHistoryDto {
    private String id;            // 문서 id
    private String uid;           // 사용자 uid
    private String type;          // "earn" | "spend" | "event" | "invite" | "receipt" 등
    private String title;         // 제목
    private String detail;        // 상세
    private Long amount;          // 변화량(+적립, -사용)
    private Long balanceAfter;    // 변화 후 잔액
    private Instant createdAt;    // 생성시각
}