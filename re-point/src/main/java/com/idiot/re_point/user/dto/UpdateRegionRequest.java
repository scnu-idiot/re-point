package com.idiot.re_point.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class UpdateRegionRequest {
    /** 프론트에서 선택한 지역 문자열(예: "서울-강남구" 혹은 코드값) */
    private String region;
}