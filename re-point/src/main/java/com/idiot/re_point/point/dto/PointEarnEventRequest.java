package com.idiot.re_point.point.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class PointEarnEventRequest {
    private Long amount;
    private String eventId;       // 혹은 campaignCode
    private String title;
    private String detail;
}